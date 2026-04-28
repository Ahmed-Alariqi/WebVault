import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore - Deno JSR import not recognized by standard TS server
import { createClient } from "jsr:@supabase/supabase-js@2";
// Provide Deno global space for typescript IDE
declare const Deno: any;

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

let cachedPersonas: Map<string, any> = new Map();
let cachedProviders: Map<string, any> = new Map();
let lastCacheRefresh = 0;
const CACHE_TTL = 5 * 60 * 1000;

async function refreshCache() {
  const now = Date.now();
  if (now - lastCacheRefresh < CACHE_TTL && cachedPersonas.size > 0) return;

  const { data: providers } = await supabaseAdmin
    .from('ai_providers').select('*').eq('is_active', true);
  const { data: personas } = await supabaseAdmin
    .from('ai_personas').select('*, ai_providers(*)').eq('is_active', true);

  cachedProviders.clear();
  for (const p of providers ?? []) cachedProviders.set(p.id, p);
  cachedPersonas.clear();
  for (const p of personas ?? []) cachedPersonas.set(p.id, p);

  lastCacheRefresh = now;
}

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-id',
};

// ── Suggestions Protocol ─────────────────────────────────────────────────
// Layer 3 system instruction injected into every persona/mode request.
// Tells the model to append 3 contextual follow-up suggestions in a
// machine-parseable marker. The Flutter UI strips the marker from the
// rendered bubble (`_getCleanContent`) and renders the suggestions as
// tappable chips below the message (`_buildSuggestions` in zad_expert_screen.dart).
const SUGGESTIONS_PROTOCOL = `[بروتوكول الاقتراحات اللاحقة]

في نهاية كل رد (وفقط بعد إكمال المحتوى الرئيسي بالكامل)، أضف بالضبط 3 اقتراحات قصيرة لرسائل المتابعة المنطقية ذات صلة بسياق الحوار، بهذه الصيغة الحرفية على سطر منفصل في النهاية:

[SUGGESTIONS]اقتراح أول|اقتراح ثاني|اقتراح ثالث[/SUGGESTIONS]

قواعد إلزامية:
1) كل اقتراح هو **سؤال أو طلب يكتبه المستخدم في رسالته التالية** — اكتبه بضمير المستخدم وكأنه يقوله الآن (مثل: "اشرح أكثر"، "أعطني مثالاً تطبيقياً"، "اختبرني في هذا"). لا تكتبه بصيغة عرض ("هل تريد X؟" خطأ).
2) طول كل اقتراح: 3-8 كلمات بالعربية الفصيحة الواضحة.
3) التنوع مطلوب بين الاقتراحات الثلاثة:
   - واحد للتعميق أو التوضيح أو التفصيل.
   - واحد للتطبيق أو المثال أو الكود العملي.
   - واحد للاختبار أو التمرين أو الخطوة التالية المنطقية.
4) اربط الاقتراحات بالسياق الفعلي للحوار والوضع النشط — لا اقتراحات عامّة جوفاء ولا مكرّرة من ردود سابقة.
5) ضع الـ marker كآخر شيء في ردّك حرفياً، على سطر منفصل بعد فراغ.
6) لا تذكر الـ marker في المحتوى المرئي ولا تشرحه ولا تترجم اسمه.
7) لا تطبّق هذا البروتوكول على ردود الاعتذار أو رسائل الخطأ القصيرة جداً (أقل من 20 كلمة).
8) إذا كان الوضع النشط تعليمياً (مثل مدرّب قواعد البيانات)، اجعل الاقتراحات تحفّز التعلّم: "اختبرني"، "اشرح بمثال آخر"، "ما الخطأ الشائع؟".
9) إذا كان الوضع تصميمياً (ERD، architecture، class…)، اجعل الاقتراحات تطوّر التصميم: "أضف جدول كذا"، "حوّل لـ 3NF"، "ولّد CREATE TABLE".

مثال صحيح في نهاية رد عن JOINs:
[SUGGESTIONS]اشرح LEFT JOIN بمثال|أعطني تمريناً على JOINs|ما الفرق بين INNER و LEFT؟[/SUGGESTIONS]`;

// ── Usage logging (fire-and-forget, never blocks the request) ────────────
interface UsageLogParams {
  userId: string | null;
  personaId: string | null;
  providerId: string | null;
  keySuffix: string | null;
  statusCode: number;
  durationMs: number;
  errorMessage?: string | null;
  isStream: boolean;
  modeKey?: string | null;
}

function logUsage(p: UsageLogParams): void {
  supabaseAdmin
    .from('ai_usage_log')
    .insert({
      user_id: p.userId,
      persona_id: p.personaId,
      provider_id: p.providerId,
      key_suffix: p.keySuffix,
      status_code: p.statusCode,
      duration_ms: p.durationMs,
      error_message: p.errorMessage ?? null,
      is_stream: p.isStream,
      mode_key: p.modeKey ?? null,
    })
    .then(() => {})
    .catch((e: any) => console.error('logUsage failed:', e?.message ?? e));
}

// Resolve which mode (if any) applies for this request. Order:
//   1) explicit `mode_key` from client (must exist in persona.modes & enabled)
//   2) the persona's default mode (is_default = true)
//   3) null → fall back to persona-only behaviour (legacy)
function resolveMode(persona: any, requestedKey: string | null): any | null {
  const modes = Array.isArray(persona?.modes) ? persona.modes : [];
  if (modes.length === 0) return null;

  if (requestedKey && typeof requestedKey === 'string') {
    const found = modes.find((m: any) => m?.key === requestedKey && m?.enabled !== false);
    if (found) return found;
  }
  const def = modes.find((m: any) => m?.is_default === true && m?.enabled !== false);
  return def ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  const startTs = Date.now();
  const userIdHeader = req.headers.get('x-user-id') || '';
  const userId = userIdHeader.length === 36 ? userIdHeader : null;

  let personaIdForLog: string | null = null;
  let providerIdForLog: string | null = null;
  let resolvedModeKey: string | null = null;

  try {
    const body = await req.json();
    const { persona_id, messages, stream, mode_key } = body;

    if (!messages || !Array.isArray(messages)) {
      logUsage({ userId, personaId: null, providerId: null, keySuffix: null,
        statusCode: 400, durationMs: Date.now() - startTs,
        errorMessage: 'messages array is required', isStream: !!stream });
      return jsonResponse({ error: 'messages array is required' }, 400);
    }
    if (!persona_id) {
      logUsage({ userId, personaId: null, providerId: null, keySuffix: null,
        statusCode: 400, durationMs: Date.now() - startTs,
        errorMessage: 'persona_id is required', isStream: !!stream });
      return jsonResponse({ error: 'persona_id is required' }, 400);
    }

    personaIdForLog = persona_id;

    await refreshCache();

    const persona = cachedPersonas.get(persona_id);
    if (!persona) {
      logUsage({ userId, personaId: persona_id, providerId: null, keySuffix: null,
        statusCode: 404, durationMs: Date.now() - startTs,
        errorMessage: 'Persona not found or inactive', isStream: !!stream });
      return jsonResponse({ error: 'Persona not found or inactive' }, 404);
    }

    const provider = persona.ai_providers;
    if (!provider || !provider.is_active) {
      logUsage({ userId, personaId: persona_id, providerId: provider?.id ?? null, keySuffix: null,
        statusCode: 503, durationMs: Date.now() - startTs,
        errorMessage: 'AI provider is not available', isStream: !!stream });
      return jsonResponse({ error: 'AI provider is not available' }, 503);
    }

    providerIdForLog = provider.id;

    // ── Unified system prompt ──────────────────────────────────────────
    // CRITICAL: We MUST send a single consolidated system message instead of
    // multiple `role: system` entries. Many providers (notably Ollama Cloud
    // models using Llama/Gemini chat templates) only honour the LAST system
    // message in the array and silently drop earlier ones. That caused the
    // persona identity + mode prompt to be ignored, leaving only the
    // suggestions protocol as the effective system instruction → the model
    // would answer "من أنت؟" with a generic self-description because it
    // never actually saw the persona's system_instruction.
    //
    // Solution: concatenate all layers into ONE system message with clear
    // section separators. Works uniformly across OpenAI, Groq, Ollama,
    // OpenRouter, and any future provider.
    const personaPrompt = persona.system_instruction || 'أنت مساعد ذكي. أجب بوضوح ودقة.';
    const requestedModeKey = typeof mode_key === 'string' && mode_key.trim() ? mode_key.trim() : null;
    const mode = resolveMode(persona, requestedModeKey);
    resolvedModeKey = mode?.key ?? null;

    const sections: string[] = [];

    // Layer 1 — persona identity (most important, goes first).
    sections.push(`# هويتك وتعليماتك الأساسية (إلزامية)\n\n${personaPrompt}`);

    // Layer 2 — mode methodology + output template (optional).
    if (mode && typeof mode.system_prompt === 'string' && mode.system_prompt.trim().length > 0) {
      let modeContent = `# الوضع النشط: ${mode.name ?? mode.key}\n\n${mode.system_prompt}`;
      if (typeof mode.output_template === 'string' && mode.output_template.trim().length > 0) {
        modeContent += `\n\n## قالب الإخراج الموصى به\n${mode.output_template}`;
      }
      sections.push(modeContent);
    }

    // Layer 3 — suggestions protocol (UI integration; least identity-defining).
    sections.push(`# بروتوكول الاقتراحات اللاحقة (للواجهة)\n\n${SUGGESTIONS_PROTOCOL}`);

    const unifiedSystemPrompt = sections.join('\n\n---\n\n');

    const llmMessages: any[] = [
      { role: 'system', content: unifiedSystemPrompt },
      ...messages,
    ];

    const ctx = {
      userId,
      personaId: persona_id,
      startTs,
      modeKey: resolvedModeKey,
    };

    if (stream === true) {
      return await callProviderStream(
        provider,
        persona.model_id,
        llmMessages,
        persona.temperature ?? 0.5,
        persona.max_tokens ?? 4096,
        ctx,
      );
    }

    const result = await callProvider(
      provider,
      persona.model_id,
      llmMessages,
      persona.temperature ?? 0.5,
      persona.max_tokens ?? 4096,
      ctx,
    );
    return jsonResponse({ content: result, mode_key: resolvedModeKey });

  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    console.error('Zad Expert Error:', msg);
    logUsage({ userId, personaId: personaIdForLog, providerId: providerIdForLog, keySuffix: null,
      statusCode: 500, durationMs: Date.now() - startTs,
      errorMessage: msg, isStream: false, modeKey: resolvedModeKey });
    return jsonResponse({ error: msg }, 500);
  }
});

// Streaming branch — normalises ANY provider output into our SSE format.
async function callProviderStream(
  provider: any,
  modelId: string,
  messages: any[],
  temperature: number,
  maxTokens: number,
  ctx: { userId: string | null; personaId: string; startTs: number; modeKey: string | null },
): Promise<Response> {
  const apiKeys = parseApiKeys(provider.api_key);
  if (apiKeys.length === 0) {
    logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id, keySuffix: null,
      statusCode: 500, durationMs: Date.now() - ctx.startTs,
      errorMessage: `No API keys configured for provider: ${provider.name}`, isStream: true,
      modeKey: ctx.modeKey });
    return jsonResponse({ error: `No API keys configured for provider: ${provider.name}` }, 500);
  }
  const isOllama = (provider.slug || '').toLowerCase().includes('ollama');

  let upstream: Response | null = null;
  let usedKey: string | null = null;
  let lastErr = '';
  for (const key of apiKeys) {
    try {
      const res = await fetch(provider.base_url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${key}`,
        },
        body: JSON.stringify(
          isOllama
            ? { model: modelId, messages, stream: true, options: { temperature, num_predict: maxTokens } }
            : { model: modelId, messages, temperature, max_tokens: maxTokens, stream: true },
        ),
      });
      if (res.ok) { upstream = res; usedKey = key; break; }
      if (res.status === 401 || res.status === 429) {
        lastErr = `${res.status}`;
        logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
          keySuffix: key.slice(-4), statusCode: res.status,
          durationMs: Date.now() - ctx.startTs,
          errorMessage: `key_failover ${res.status}`, isStream: true, modeKey: ctx.modeKey });
        try { await res.body?.cancel(); } catch {}
        continue;
      }
      const errText = await res.text();
      logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
        keySuffix: key.slice(-4), statusCode: res.status,
        durationMs: Date.now() - ctx.startTs,
        errorMessage: errText.slice(0, 300), isStream: true, modeKey: ctx.modeKey });
      return jsonResponse({ error: `Provider ${provider.slug} ${res.status}: ${errText}` }, 502);
    } catch (e: any) {
      lastErr = e?.message ?? 'fetch failed';
      continue;
    }
  }
  if (!upstream || !upstream.body) {
    logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id, keySuffix: null,
      statusCode: 502, durationMs: Date.now() - ctx.startTs,
      errorMessage: `All keys failed (last: ${lastErr})`, isStream: true, modeKey: ctx.modeKey });
    return jsonResponse({ error: `All keys failed (last: ${lastErr})` }, 502);
  }

  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const writeContent = (controller: ReadableStreamDefaultController, content: string) => {
    if (typeof content === 'string' && content.length > 0) {
      const out = JSON.stringify({ content });
      controller.enqueue(encoder.encode(`data: ${out}\n\n`));
    }
  };

  const stream = new ReadableStream({
    async start(controller) {
      const reader = upstream!.body!.getReader();
      let buffer = '';
      let streamErrored = false;
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });

          let nl;
          while ((nl = buffer.indexOf('\n')) !== -1) {
            const rawLine = buffer.slice(0, nl);
            buffer = buffer.slice(nl + 1);
            const line = rawLine.replace(/\r$/, '').trim();
            if (line.length === 0) continue;

            let payload = line;
            if (line.startsWith('data:')) {
              payload = line.slice(5).trim();
              if (payload === '[DONE]') {
                controller.enqueue(encoder.encode('data: [DONE]\n\n'));
                controller.close();
                logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
                  keySuffix: usedKey ? usedKey.slice(-4) : null,
                  statusCode: 200, durationMs: Date.now() - ctx.startTs,
                  errorMessage: null, isStream: true, modeKey: ctx.modeKey });
                return;
              }
            } else if (!line.startsWith('{')) {
              continue;
            }

            try {
              const j = JSON.parse(payload);
              const delta = j.choices?.[0]?.delta?.content;
              if (typeof delta === 'string') writeContent(controller, delta);
              const fullMsg = j.choices?.[0]?.message?.content;
              if (typeof fullMsg === 'string') writeContent(controller, fullMsg);
              if (j.message?.content && typeof j.message.content === 'string') {
                writeContent(controller, j.message.content);
              }
              if (j.done === true) {
                controller.enqueue(encoder.encode('data: [DONE]\n\n'));
                controller.close();
                logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
                  keySuffix: usedKey ? usedKey.slice(-4) : null,
                  statusCode: 200, durationMs: Date.now() - ctx.startTs,
                  errorMessage: null, isStream: true, modeKey: ctx.modeKey });
                return;
              }
            } catch (_) { /* skip malformed */ }
          }
        }
        if (buffer.trim().length > 0) {
          try {
            const tail = buffer.startsWith('data:') ? buffer.slice(5).trim() : buffer.trim();
            if (tail !== '[DONE]') {
              const j = JSON.parse(tail);
              const delta = j.choices?.[0]?.delta?.content
                ?? j.choices?.[0]?.message?.content
                ?? j.message?.content;
              if (typeof delta === 'string') writeContent(controller, delta);
            }
          } catch (_) {}
        }
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
        logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
          keySuffix: usedKey ? usedKey.slice(-4) : null,
          statusCode: 200, durationMs: Date.now() - ctx.startTs,
          errorMessage: null, isStream: true, modeKey: ctx.modeKey });
      } catch (err: any) {
        streamErrored = true;
        const msg = err?.message ?? 'stream error';
        const out = JSON.stringify({ error: msg });
        controller.enqueue(encoder.encode(`data: ${out}\n\n`));
        controller.close();
        logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
          keySuffix: usedKey ? usedKey.slice(-4) : null,
          statusCode: 500, durationMs: Date.now() - ctx.startTs,
          errorMessage: msg, isStream: true, modeKey: ctx.modeKey });
      }
      void streamErrored;
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
      ...CORS,
    },
  });
}

// ── Non-streaming fallback (kept for backward compatibility) ──
async function callProvider(
  provider: any,
  modelId: string,
  messages: any[],
  temperature: number,
  maxTokens: number,
  ctx: { userId: string | null; personaId: string; startTs: number; modeKey: string | null },
): Promise<string> {
  const apiKeys = parseApiKeys(provider.api_key);
  if (apiKeys.length === 0) {
    logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id, keySuffix: null,
      statusCode: 500, durationMs: Date.now() - ctx.startTs,
      errorMessage: `No API keys configured for provider: ${provider.name}`, isStream: false,
      modeKey: ctx.modeKey });
    throw new Error(`No API keys configured for provider: ${provider.name}`);
  }

  let lastError: Error | null = null;
  const isOllama = (provider.slug || '').toLowerCase().includes('ollama');

  for (const key of apiKeys) {
    try {
      const res = await fetch(provider.base_url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${key}`,
        },
        body: JSON.stringify(
          isOllama
            ? { model: modelId, messages, stream: false, options: { temperature, num_predict: maxTokens } }
            : { model: modelId, messages, temperature, max_tokens: maxTokens, stream: false }
        ),
      });
      if (!res.ok) {
        const errorText = await res.text();
        if (res.status === 401 || res.status === 429) {
          lastError = new Error(`Provider ${provider.slug} error ${res.status}: ${errorText}`);
          logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
            keySuffix: key.slice(-4), statusCode: res.status,
            durationMs: Date.now() - ctx.startTs,
            errorMessage: `key_failover ${res.status}`, isStream: false, modeKey: ctx.modeKey });
          continue;
        }
        logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
          keySuffix: key.slice(-4), statusCode: res.status,
          durationMs: Date.now() - ctx.startTs,
          errorMessage: errorText.slice(0, 300), isStream: false, modeKey: ctx.modeKey });
        throw new Error(`Provider ${provider.slug} error ${res.status}: ${errorText}`);
      }
      const data = await res.json();
      const content = data.choices?.[0]?.message?.content
        ?? data.message?.content
        ?? data.content
        ?? data.response
        ?? '';
      logUsage({ userId: ctx.userId, personaId: ctx.personaId, providerId: provider.id,
        keySuffix: key.slice(-4), statusCode: 200,
        durationMs: Date.now() - ctx.startTs,
        errorMessage: null, isStream: false, modeKey: ctx.modeKey });
      return content;
    } catch (err: any) {
      lastError = err;
      if (err.message?.includes('fetch')) continue;
      throw err;
    }
  }
  throw lastError || new Error('All API keys failed.');
}

function parseApiKeys(raw: string): string[] {
  if (!raw) return [];
  return raw.split(',').map(k => k.trim()).filter(Boolean);
}

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS,
    },
  });
}
