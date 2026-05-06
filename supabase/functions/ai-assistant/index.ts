import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore - Deno JSR import not recognized by standard TS server
import { createClient } from "jsr:@supabase/supabase-js@2";
// Provide Deno global space for typescript IDE
declare const Deno: any;

// ════════════════════════════════════════════════════════════════════════════
// AI Assistant — DB-driven providers
// ════════════════════════════════════════════════════════════════════════════
//
// Previously the API keys, base URL and model were hardcoded in this file
// (or read from `Deno.env`). That meant changing the model, rotating a
// burnt key, or adding a new fallback provider required editing the
// source and redeploying — a friction point we hit in production.
//
// The function now reads its configuration from the `ai_providers` table
// rows whose `purpose = 'ai-assistant'` (and `is_active = true`). The
// admin manages those rows from inside the app via the AI Management
// screen, so updates are instant and require no code changes.
//
// Each provider row contributes:
//   • base_url        → the chat-completions endpoint to POST to
//   • api_key         → comma-separated list of keys (rotated on 401/429)
//   • selected_model  → model to send (falls back to supported_models[0])
//
// We try each provider in order; within a provider we try each key in
// order. This preserves the historical failover behaviour while letting
// the admin run several providers side-by-side (e.g. Groq + Ollama) for
// resilience.
// ════════════════════════════════════════════════════════════════════════════

const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

interface AssistantProvider {
    baseUrl: string;
    keys: string[];
    model: string;
}

let cachedProviders: AssistantProvider[] = [];
let lastCacheRefresh = 0;
const CACHE_TTL_MS = 60_000; // 1 minute — fresh enough that admin edits show up almost immediately, slow enough to keep cold-call latency low.

async function loadProviders(): Promise<AssistantProvider[]> {
    const now = Date.now();
    if (now - lastCacheRefresh < CACHE_TTL_MS && cachedProviders.length > 0) {
        return cachedProviders;
    }

    const { data, error } = await supabaseAdmin
        .from('ai_providers')
        .select('base_url, api_key, supported_models, selected_model')
        .eq('purpose', 'ai-assistant')
        .eq('is_active', true)
        .order('created_at', { ascending: true });

    if (error) {
        console.error('Failed to load ai-assistant providers:', error.message);
        // On error, keep serving the previously-cached config rather than
        // 500-ing every chat request. The next refresh will retry.
        return cachedProviders;
    }

    const built: AssistantProvider[] = [];
    for (const row of data ?? []) {
        const keys = String(row.api_key ?? '')
            .split(',')
            .map((k: string) => k.trim())
            .filter(Boolean);
        if (keys.length === 0) continue;

        const baseUrl = String(row.base_url ?? '').trim();
        if (!baseUrl) continue;

        const supported: string[] = Array.isArray(row.supported_models)
            ? row.supported_models.map((m: unknown) => String(m).trim()).filter(Boolean)
            : [];
        const explicit = (row.selected_model ?? '').toString().trim();
        const model = explicit || supported[0] || '';
        if (!model) continue;

        built.push({ baseUrl, keys, model });
    }

    cachedProviders = built;
    lastCacheRefresh = now;
    return cachedProviders;
}

const SYSTEM_INSTRUCTION = `أنت "مرشد زاد الذكي"، المساعد الذكي داخل تطبيق "زاد التقني".

مهمتك هي شرح وتلخيص عناصر المستكشف التقني والإجابة عن أسئلة المستخدم بوضوح، إيجاز، وبطريقة مهنية وودودة.

التعليمات الأساسية:
1. استند أولاً وأخيراً على "سياق العنصر الحالي" المرفق.
2. إذا كان السؤال يحتاج لتفاصيل أعمق غير متوفرة في السياق، استخدم أداة \`fetch_url_content\` لفحص الرابط المرفق.
3. التزم باللغة العربية الواضحة والمبسطة، وكن ودوداً واحترافياً.
4. ابدأ دائمًا بالإجابة المباشرة، وتجنب الإطالة الكبيرة.
5. لا تخترع معلومات من عندك (Hallucination) إطلاقاً.
6. إذا طلب المستخدم روابط، ضع روابط حقيقية وصحيحة. تنبيه هام جداً: يُمنع منعاً باتاً إنشاء روابط فارغة بهذا الشكل [Text]({}). استخدم الرابط الفعلي المتوفر في السياق فقط.
7. لا تتحدث خارج سياق العنصر الحالي. إذا سألك المستحدم خارج السياق، اعتذر وأخبره بمهامك.
8. قم دوماً باستخدام تظليل الأكواد (Markdown Syntax) للأكواد البرمجية (مثل \`\`\`dart الكود... \`\`\`) وللنصوص الهامة لجعل القراءة سهلة.`;

const TOOLS = [
    {
        type: 'function',
        function: {
            name: 'fetch_url_content',
            description: 'Fetch and read the content of a URL when you need details not present in the general context. DO NOT output links with empty parentheses.',
            parameters: {
                type: 'object',
                required: ['url'],
                properties: {
                    url: {
                        type: 'string',
                        description: 'The exact URL to fetch content from.',
                    },
                },
            },
        },
    },
];

// ── URL Content Fetcher (Jina AI Reader + fallback) ──
async function fetchUrlContent(url: string): Promise<string> {
    try {
        const jinaUrl = `https://r.jina.ai/${url}`;
        const jinaRes = await fetch(jinaUrl, {
            headers: {
                'Accept': 'text/plain',
                'X-No-Cache': 'true',
                'X-Retain-Images': 'none',
                'X-With-Shadow-Dom': 'true',
                'X-Timeout': '15',
            },
        });

        if (jinaRes.ok) {
            const text = await jinaRes.text();
            if (text && text.length > 100) {
                return text.slice(0, 12000);
            }
        }
    } catch {
        // Jina failed, fall through to fallback
    }

    try {
        if (url.includes('github.com') && !url.includes('raw.githubusercontent.com')) {
            const parts = url.replace('https://github.com/', '').replace('http://github.com/', '').split('/');
            if (parts.length >= 2) {
                const owner = parts[0];
                const repo = parts[1];
                for (const branch of ['main', 'master']) {
                    try {
                        const rawUrl = `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/README.md`;
                        const res = await fetch(rawUrl);
                        if (res.ok) {
                            const text = await res.text();
                            return text.slice(0, 12000);
                        }
                    } catch { /* try next branch */ }
                }
            }
        }

        const res = await fetch(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; ZaadTechBot/1.0)',
                'Accept': 'text/html,application/xhtml+xml,text/plain,text/markdown',
            },
        });

        if (!res.ok) return `[Error: Could not fetch URL - HTTP ${res.status}]`;

        const contentType = res.headers.get('content-type') ?? '';
        const body = await res.text();

        if (contentType.includes('text/plain') || contentType.includes('text/markdown')) {
            return body.slice(0, 12000);
        }

        const text = body
            .replace(/<script[\s\S]*?<\/script>/gi, '')
            .replace(/<style[\s\S]*?<\/style>/gi, '')
            .replace(/<nav[\s\S]*?<\/nav>/gi, '')
            .replace(/<footer[\s\S]*?<\/footer>/gi, '')
            .replace(/<header[\s\S]*?<\/header>/gi, '')
            .replace(/<aside[\s\S]*?<\/aside>/gi, '')
            .replace(/<!--[\s\S]*?-->/g, '')
            .replace(/<[^>]+>/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();

        return text.slice(0, 12000);
    } catch (err) {
        return `[Error fetching URL: ${err instanceof Error ? err.message : 'Unknown error'}]`;
    }
}

// ── Build system prompt ──
function buildSystemPrompt(itemContext: Record<string, unknown>, pageContent?: string, externalContext?: string): string {
    let baseContext = `${SYSTEM_INSTRUCTION}`;

    // If we have a specific item from the vault
    if (Object.keys(itemContext).length > 0) {
        baseContext += `\n\n=== سياق العنصر الحالي ===\nالعنوان: ${itemContext.title ?? 'غير محدد'}\nالوصف: ${itemContext.description ?? 'لا يوجد وصف'}\nالرابط: ${itemContext.url ?? 'لا يوجد رابط'}\nالتصنيف: ${itemContext.tags ? (itemContext.tags as string[]).join(', ') : 'غير مصنف'}\nالنوع: ${itemContext.content_type ?? 'website'}\n=== نهاية السياق ===\n\nأجب على أسئلة المستخدم بناءً على هذا السياق، أو استخدم الأداة لقراءة الرابط: ${itemContext.url ?? ''}`;
    }

    // If we have external context (from clipboard or share)
    if (externalContext) {
        baseContext += `\n\n=== سياق خارجي للمناقشة ===\nلقد أرسل المستخدم لك هذا النص أو الرابط الخارجي للتركيز عليه:\n${externalContext}\n\n=== بناءً على هذا السياق أجب على المستخدم. هام جداً: إذا احتوى السياق الخارجي على رابط (URL) ولم تكن تعرف محتواه، *يجب* عليك فوراً استخدام أداة \`fetch_url_content\` لقرائته ثم الإجابة بناءً على ما قرأته. ===`;
    }

    if (pageContent) {
        baseContext += `\n\n=== محتوى الصفحة المستخرج مباشرة ===\nهذا هو النص المستخرج من الصفحة الحالية في المتصفح. اعتمد عليه كلياً كمصدرك الأساسي للإجابة على الأسئلة حول هذه الصفحة بدلاً من قراءة الرابط.\nإذا كان الموقع عبارة عن أداة أو مكتبة تقنية، اشرح ما هي، ولماذا هي مفيدة، وما هي طريقة التثبيت، وقدم أمثلة عملية بناءً على المحتوى المتوفر:\n\n${pageContent}\n=== نهاية المحتوى المستخرج ===`;
    }

    return baseContext;
}

// ── Main Handler ──
Deno.serve(async (req: Request) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            },
        });
    }

    try {
        const body = await req.json();
        const { item_context, messages, page_content, external_context } = body;

        if (!messages || !Array.isArray(messages)) {
            return new Response(JSON.stringify({ error: 'messages array is required' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        const systemPrompt = buildSystemPrompt(item_context ?? {}, page_content, external_context);

        const llmMessages = [
            { role: 'system', content: systemPrompt },
            ...messages,
        ];

        let llmResponse = await callLLM(llmMessages, true);

        let rounds = 0;
        while (llmResponse.tool_calls && llmResponse.tool_calls.length > 0 && rounds < 2) {
            rounds++;

            llmMessages.push({
                role: 'assistant',
                content: llmResponse.content ?? '',
                tool_calls: llmResponse.tool_calls,
            } as any);

            for (const toolCall of llmResponse.tool_calls) {
                if (toolCall.function.name === 'fetch_url_content') {
                    const rawArgs = toolCall.function.arguments;
                    let argsUrl = '';

                    if (typeof rawArgs === 'string') {
                        try { argsUrl = JSON.parse(rawArgs).url; } catch { /* ignore */ }
                    } else if (rawArgs && typeof rawArgs === 'object') {
                        argsUrl = (rawArgs as any).url;
                    }

                    if (!argsUrl && (item_context as any)?.url) {
                        argsUrl = (item_context as any).url as string;
                    }

                    // Fallback to external_context if it looks like a URL
                    if (!argsUrl && typeof external_context === 'string' && external_context.startsWith('http')) {
                        argsUrl = external_context.trim();
                    }

                    const content = await fetchUrlContent(argsUrl || 'invalid-url');

                    llmMessages.push({
                        role: 'tool',
                        tool_name: toolCall.function.name,
                        content: content,
                    } as any);
                }
            }

            llmResponse = await callLLM(llmMessages, true);
        }

        return new Response(JSON.stringify({ content: llmResponse.content ?? '' }), {
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });

    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Unknown error';
        console.error('AI Assistant Error:', errorMsg);
        return new Response(JSON.stringify({ error: errorMsg }), {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }
});

// ── Call LLM API ──
//
// Two-level failover:
//   1. Try providers in DB order (oldest → newest).
//   2. Within a provider, try its keys in order.
// On 401/429 we silently move to the next key/provider; on any other
// non-2xx we surface the error immediately (it's likely a payload bug).
async function callLLM(
    messages: Array<Record<string, unknown>>,
    includeTools: boolean,
): Promise<{ content: string | null; tool_calls?: Array<any> }> {
    const providers = await loadProviders();

    if (providers.length === 0) {
        throw new Error(
            'No active AI Assistant providers configured. Add one from the admin AI Management screen (Providers tab → "المساعد الذكي العام").',
        );
    }

    let lastError: Error | null = null;

    for (const provider of providers) {
        const payload: Record<string, unknown> = {
            model: provider.model,
            messages,
            stream: false,
        };
        if (includeTools) payload.tools = TOOLS;

        for (const key of provider.keys) {
            try {
                const res = await fetch(provider.baseUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${key}`,
                    },
                    body: JSON.stringify(payload),
                });

                if (!res.ok) {
                    const errorText = await res.text();
                    // Soft failover: invalid/expired key (401) or rate
                    // limited (429) — keep trying remaining keys/providers.
                    if (res.status === 401 || res.status === 429) {
                        console.log(
                            `[ai-assistant] ${provider.baseUrl} key ...${key.slice(-4)} failed ${res.status}; trying next.`,
                        );
                        lastError = new Error(
                            `LLM API error ${res.status}: ${errorText}`,
                        );
                        continue;
                    }
                    // Hard error — surface to caller immediately.
                    throw new Error(`LLM API error ${res.status}: ${errorText}`);
                }

                const data = await res.json();
                const choice = data.message ?? data.choices?.[0]?.message;

                return {
                    content: choice?.content ?? null,
                    tool_calls: choice?.tool_calls,
                };
            } catch (err: any) {
                lastError = err;
            }
        }
    }

    throw lastError || new Error('All AI Assistant providers/keys failed.');
}
