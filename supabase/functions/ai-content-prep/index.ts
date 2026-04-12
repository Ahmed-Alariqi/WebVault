import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// Provide Deno global space for typescript IDE
declare const Deno: any;

const OLLAMA_API_KEY = Deno.env.get('OLLAMA_API_KEY') || '';
const LLM_BASE_URL = Deno.env.get('LLM_BASE_URL') || 'https://ollama.com/api/chat';
const DEFAULT_LLM_MODEL = 'gemini-3-flash-preview:cloud';

const SYSTEM_INSTRUCTION = `You are an expert Arabic tech content editor, content strategist, and taxonomy assistant for a publishing app.
Your task is to transform raw user-provided content into a polished, concise, professional, and publish-ready Arabic entry for a modern tech platform.

The platform publishes content under these Arabic main categories only:
أدوات
كورسات
عروض واشتراكات
مواقع ومصادر
اخبار
تلقينات
شروحات

================================================== CORE GOAL
Turn any raw input into a high-quality Arabic publishing entry that is:
clear, concise, accurate, useful, easy to scan, structurally appropriate to the content itself.

The output must always include:
title, category_name, subcategory, description (rich formatted), content_type, tags, source_url (if detectable)

================================================== PRIMARY RULE
Do NOT force one repeated structure across all content.
Before writing, identify the content type and choose the SINGLE most suitable presentation style.
Prioritize a natural, custom-written result over a formulaic template.

================================================== DESCRIPTION FORMAT RULES
The description field MUST be a RICH, DETAILED, structured description. NOT just 2-3 lines.
It must follow this structure based on the content type:

For Tools (أدوات):
- Start with 2-3 sentence overview
- Then add a section "أبرز المميزات:" with bullet points
- Then add a section "أهم الاستخدامات:" with bullet points

For Websites/Resources (مواقع ومصادر):
- Start with 2-3 sentence overview
- Then add "ماذا ستجد؟" with bullet points
- Optionally add "الفئة المستهدفة:" 

For Courses (كورسات):
- Start with 2-3 sentence overview
- Then add "ماذا ستتعلم؟" with bullet points
- Then add "مناسب لمن؟" briefly

For News (اخبار):
- Start with 2-3 sentence overview
- Then add "ما الجديد؟" or "أبرز النقاط:" with bullet points
- Then add "لماذا يهم؟" briefly

For Prompts (تلقينات):
- Start with 2-3 sentence overview
- Then add "الاستخدامات:" with bullet points
- Then add "متى يفيدك؟" briefly

For Tutorials (شروحات):
- Start with 2-3 sentence overview
- Then add "خطوات الشرح:" or "ما الذي ستتعلمه؟" with bullet points
- Then add "متى يفيدك؟" briefly

For Offers (عروض واشتراكات):
- Start with 2-3 sentence overview
- Then add "تفاصيل العرض:" with bullet points
- Then add "طريقة الاستفادة:" briefly

Use line breaks (\\n) to separate sections. Use "• " for bullet points.
Do NOT use markdown headers (#). Use plain text section titles followed by a colon.

The INFORMATION DENSITY RULE applies: only add sections if the source gives meaningful data.
Do NOT pad or inflate sections with generic filler.

================================================== WRITING STYLE
Write in modern professional Arabic.
The tone must be: polished, smooth, concise, natural, publication-ready.

Avoid: robotic phrasing, repetitive wording, exaggerated marketing language, unnecessary hype, slang, emojis.
Do not repeat the same idea across the title, description.

================================================== TITLE RULES
The title must: be in Arabic, be specific, clear, and strong, fit a publishing card, reflect the real value.
Avoid clickbait, vague wording, excessive punctuation, exaggerated claims.

================================================== MAIN CATEGORY RULES
Choose exactly ONE main category from the categories list provided in the user message.
Never create a new main category.

================================================== SUBCATEGORY RULES
Choose exactly ONE subcategory.
For all main categories except "تلقينات", use ONLY:
ذكاء اصطناعي, برمجة, بحث, انتاجية, تصميم, امن سيبراني, اعمال وتسويق, تعليم, عام

For "تلقينات", use ONLY:
توليد صور, تعديل صور, توليد فيديو, كتابة, برمجة, تحليل, أتمتة, أسلوب وتحكم, عام

================================================== CONTENT TYPE MAPPING
أدوات → tool, كورسات → course, عروض واشتراكات → offer, مواقع ومصادر → website, اخبار → announcement, تلقينات → prompt, شروحات → tutorial

================================================== HASHTAG RULES
3 to 6 hashtags.
CRITICAL: ALL TAGS MUST BE IN EXACT ENGLISH ONLY. NO ARABIC TAGS ALLOWED. 
Write concise, relevant, discovery-friendly, lowercase English programming/tech tags (e.g. "ai", "javascript", "design", "security"). No duplicates.

================================================== SOURCE URL EXTRACTION
If the input contains a URL, extract it and return it in the "source_url" field.
If the input is a URL itself, use that as source_url.
If no URL is present, set source_url to empty string.

================================================== STRICT OUTPUT RULES
Return ONLY valid JSON. No text before or after the JSON.
{
  "title": "[strong Arabic title]",
  "description": "[RICH structured Arabic description with sections and bullet points as specified above]",
  "category_name": "[one valid Arabic main category]",
  "subcategory": "[one valid Arabic subcategory]",
  "content_type": "[mapped content type]",
  "tags": ["tag1_english", "tag2_english", "tag3_english"],
  "source_url": "[extracted URL or empty string]"
}

Do NOT add any text, explanation, reasoning, or commentary outside the JSON object.
Do NOT use markdown code fences. Return raw JSON only.`;

const FIELD_REGEN_INSTRUCTION = `You are a precise content editor. You will be given context about a content entry and asked to regenerate ONLY a specific field.
Return ONLY the regenerated field value as a JSON object with a single key matching the field name.
Keep the same quality standards and style as the original.
For description fields, follow the same rich structured format with sections and bullet points.

CRITICAL TAGS RULE: If regenerating "tags", ALL TAGS MUST BE EXACT ENGLISH ONLY. NO ARABIC TAGS. Return e.g. {"tags": ["flutter", "dart", "ui"]}.

Do NOT return any text outside the JSON.`;

const TOOLS = [
    {
        type: 'function',
        function: {
            name: 'fetch_url_content',
            description: 'Fetch and read the content of a URL to analyze it.',
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
        // fall through to fallback
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
                    } catch { /* try next */ }
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
        const requestedModel = (body.model as string) || DEFAULT_LLM_MODEL;

        if (body.regenerate_field) {
            return await handleFieldRegeneration(body, requestedModel);
        }

        return await handleFullGeneration(body, requestedModel);
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : 'Unknown error';
        console.error('AI Content Prep Error:', errorMsg);
        return new Response(JSON.stringify({ error: errorMsg }), {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }
});

async function handleFullGeneration(body: Record<string, unknown>, targetModel: string) {
    const { input, categories, content_types } = body;

    if (!input || typeof input !== 'string' || input.trim().length === 0) {
        return new Response(JSON.stringify({ error: 'input is required' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }

    const categoriesList = (categories as string[]) || [];
    const contentTypesList = (content_types as string[]) || [];

    const userPrompt = `المدخل: ${(input as string).trim()}

التصنيفات الرئيسية المتاحة: [${categoriesList.join('، ')}]
أنواع المحتوى المتاحة: [${contentTypesList.join(', ')}]

قم بتحليل المدخل وأرجع JSON منظم فقط. تذكر: الوصف يجب أن يكون غنياً ومفصلاً، والتاجات (Tags) يجب أن تكون *بالإنجليزية فقط*.`;

    const llmMessages: Array<Record<string, unknown>> = [
        { role: 'system', content: SYSTEM_INSTRUCTION },
        { role: 'user', content: userPrompt },
    ];

    const isUrl = /^https?:\/\//i.test((input as string).trim());
    let llmResponse = await callLLM(llmMessages, isUrl, targetModel);

    let rounds = 0;
    while (llmResponse.tool_calls && llmResponse.tool_calls.length > 0 && rounds < 2) {
        rounds++;
        llmMessages.push({ role: 'assistant', content: llmResponse.content ?? '', tool_calls: llmResponse.tool_calls } as any);

        for (const toolCall of llmResponse.tool_calls) {
            if (toolCall.function.name === 'fetch_url_content') {
                const rawArgs = toolCall.function.arguments;
                let argsUrl = '';
                if (typeof rawArgs === 'string') { try { argsUrl = JSON.parse(rawArgs).url; } catch { } }
                else if (rawArgs && typeof rawArgs === 'object') { argsUrl = (rawArgs as any).url; }
                if (!argsUrl && isUrl) argsUrl = (input as string).trim();
                const content = await fetchUrlContent(argsUrl || 'invalid-url');
                llmMessages.push({ role: 'tool', tool_name: toolCall.function.name, content } as any);
            }
        }
        llmResponse = await callLLM(llmMessages, false, targetModel);
    }

    const rawContent = llmResponse.content ?? '';
    let result: Record<string, unknown>;
    try {
        const jsonMatch = rawContent.match(/\{[\s\S]*\}/);
        result = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(rawContent);
    } catch {
        return new Response(JSON.stringify({ error: 'Failed to parse AI response', raw: rawContent }), {
            status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }

    if (!result.source_url && isUrl) {
        result.source_url = (input as string).trim();
    }

    return new Response(JSON.stringify(result), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
}

async function handleFieldRegeneration(body: Record<string, unknown>, targetModel: string) {
    const { regenerate_field, current_data, original_input } = body;

    if (!regenerate_field || !current_data) {
        return new Response(JSON.stringify({ error: 'regenerate_field and current_data are required' }), {
            status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }

    const fieldName = regenerate_field as string;
    const currentData = current_data as Record<string, unknown>;

    const userPrompt = `السياق الحالي للمحتوى:
العنوان: ${currentData.title || ''}
الوصف: ${currentData.description || ''}
التصنيف: ${currentData.category_name || ''}
النوع: ${currentData.content_type || ''}
المدخل الأصلي: ${original_input || ''}

أعد توليد حقل "${fieldName}" فقط. أرجع JSON بمفتاح واحد "${fieldName}".
${fieldName === 'description' ? 'تذكر: الوصف يجب أن يكون غنياً ومفصلاً بأقسام ونقاط حسب نوع المحتوى.' : ''}
${fieldName === 'tags' ? 'أرجع {"tags": ["tag1", "tag2", ...]} حيث أن كل التاجات يجب أن تكون *بالإنجليزية فقط*.' : ''}`;

    const llmMessages: Array<Record<string, unknown>> = [
        { role: 'system', content: FIELD_REGEN_INSTRUCTION },
        { role: 'user', content: userPrompt },
    ];

    const llmResponse = await callLLM(llmMessages, false, targetModel);
    const rawContent = llmResponse.content ?? '';

    try {
        const jsonMatch = rawContent.match(/\{[\s\S]*\}/);
        const result = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(rawContent);
        return new Response(JSON.stringify(result), {
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    } catch {
        return new Response(JSON.stringify({ error: 'Failed to parse regeneration response', raw: rawContent }), {
            status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }
}

async function callLLM(
    messages: Array<Record<string, unknown>>,
    includeTools: boolean,
    targetModel: string,
): Promise<{ content: string | null; tool_calls?: Array<any> }> {
    const payload: Record<string, unknown> = { model: targetModel, messages, stream: false };
    if (includeTools) payload.tools = TOOLS;

    const res = await fetch(LLM_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${OLLAMA_API_KEY}` },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`LLM API error ${res.status}: ${errorText}`);
    }

    const data = await res.json();
    const choice = data.message;
    return { content: choice?.content ?? null, tool_calls: choice?.tool_calls };
}
