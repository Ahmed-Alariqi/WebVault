import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// Provide Deno global space for typescript IDE
declare const Deno: any;

// ==========================================
// ضع مفاتيح الـ API الخاصة بك هنا داخل هذه القائمة
// ==========================================
const HARDCODED_API_KEYS: string[] = [
    "f34d7786dc994bd799f69d90aec4b9f9.aZr057otPvcQ14zG3H-b_G_b",
    "3874c11c55a54b07bdf464856bbd3d61.Vb0V59ULNpXf28uQSK24_sfw"
];

// دمج المفاتيح المكتوبة هنا مع المتوفرة في متغيرات البيئة (إن وجدت)
const OLLAMA_API_KEYS = [
    ...HARDCODED_API_KEYS,
    ...(Deno.env.get('OLLAMA_API_KEYS') || Deno.env.get('OLLAMA_API_KEY') || '')
        .split(',')
        .map((k: string) => k.trim())
        .filter(Boolean)
];
const LLM_BASE_URL = Deno.env.get('LLM_BASE_URL') || 'https://ollama.com/api/chat';
const LLM_MODEL = Deno.env.get('LLM_MODEL') || 'gemini-3-flash-preview:cloud';

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
function buildSystemPrompt(itemContext: Record<string, unknown>, pageContent?: string): string {
    let baseContext = `${SYSTEM_INSTRUCTION}\n\n=== سياق العنصر الحالي ===\nالعنوان: ${itemContext.title ?? 'غير محدد'}\nالوصف: ${itemContext.description ?? 'لا يوجد وصف'}\nالرابط: ${itemContext.url ?? 'لا يوجد رابط'}\nالتصنيف: ${itemContext.tags ? (itemContext.tags as string[]).join(', ') : 'غير مصنف'}\nالنوع: ${itemContext.content_type ?? 'website'}\n=== نهاية السياق ===\n\nأجب على أسئلة المستخدم بناءً على هذا السياق، أو استخدم الأداة لقراءة الرابط: ${itemContext.url ?? ''}`;

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
        const { item_context, messages, page_content } = body;

        if (!messages || !Array.isArray(messages)) {
            return new Response(JSON.stringify({ error: 'messages array is required' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        const systemPrompt = buildSystemPrompt(item_context ?? {}, page_content);

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
async function callLLM(
    messages: Array<Record<string, unknown>>,
    includeTools: boolean,
): Promise<{ content: string | null; tool_calls?: Array<any> }> {
    const payload: Record<string, unknown> = {
        model: LLM_MODEL,
        messages,
        stream: false,
    };

    if (includeTools) {
        payload.tools = TOOLS;
    }

    let lastError: Error | null = null;

    if (OLLAMA_API_KEYS.length === 0) {
        throw new Error("No API keys configured.");
    }

    for (const key of OLLAMA_API_KEYS) {
        try {
            const res = await fetch(LLM_BASE_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${key}`,
                },
                body: JSON.stringify(payload),
            });

            if (!res.ok) {
                const errorText = await res.text();
                // Failover on 401 or 429
                if (res.status === 401 || res.status === 429) {
                    console.log(`Key ending in ...${key.slice(-4)} failed with ${res.status}. Trying next key...`);
                    lastError = new Error(`LLM API error ${res.status}: ${errorText}`);
                    continue;
                }
                throw new Error(`LLM API error ${res.status}: ${errorText}`);
            }

            const data = await res.json();
            const choice = data.message;

            return {
                content: choice?.content ?? null,
                tool_calls: choice?.tool_calls,
            };
        } catch (err: any) {
            lastError = err;
        }
    }

    throw lastError || new Error("All API keys failed.");
}
