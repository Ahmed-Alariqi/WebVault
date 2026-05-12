import "jsr:@supabase/functions-js/edge-runtime.d.ts";
declare const Deno: any;

/**
 * Web Tools Edge Function (V10 - Multi-Key Tavily & Optimized YouTube)
 * Features:
 * - Sequential Multi-Key support for Tavily
 * - Sequential Multi-Key support for Jina
 * - Optimized YouTube Transcript extraction
 * - Smart Web Content Cleaning
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

// ── Multi-Key Helper ──
function getKeysFromEnv(envName: string, defaultValue: string): string[] {
  const raw = Deno.env.get(envName) || defaultValue;
  return raw.split(',').map((k: string) => k.trim()).filter((k: string) => k !== '');
}

const JINA_KEYS = getKeysFromEnv('JINA_API_KEY', 'jina_24ffd32b471b4d12874db537f073ab3a5QWwG1OYu3GBnNlzvS8KSaKPx5l-');
const TAVILY_KEYS = getKeysFromEnv('TAVILY_API_KEY', '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');

const TAVILY_SEARCH_URL = 'https://api.tavily.com/search';
const JINA_SEARCH_URL = 'https://s.jina.ai/';
const JINA_READ_URL = 'https://r.jina.ai/';
const MAX_READ_CONTENT_LENGTH = 45_000;

// ── Generic Multi-Key Fetcher ──
async function fetchWithFallback(keys: string[], fetcher: (key: string) => Promise<Response>): Promise<Response> {
  let lastError = '';
  for (const key of keys) {
    try {
      const res = await fetcher(key);
      if (res.status === 402 || res.status === 401 || res.status === 429) {
        console.warn(`Key failed with ${res.status}. Trying next key...`);
        continue;
      }
      return res;
    } catch (e) {
      lastError = e.message;
      continue;
    }
  }
  throw new Error(`All keys failed. Last error: ${lastError}`);
}

// ── Search Logic (Tavily with Jina Fallback) ──

async function searchWithTavily(query: string, maxResults: number) {
  const res = await fetchWithFallback(TAVILY_KEYS, (key) => 
    fetch(TAVILY_SEARCH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: key,
        query: query,
        search_depth: "advanced",
        max_results: maxResults,
        include_images: false,
      }),
    })
  );

  if (!res.ok) throw new Error(`Tavily final fail: ${res.status}`);
  const json = await res.json();
  return (json.results ?? []).map((item: any) => ({
    title: item.title ?? '',
    url: item.url ?? '',
    description: (item.content ?? '').slice(0, 800),
  }));
}

async function searchWithJina(query: string, maxResults: number) {
  const url = `${JINA_SEARCH_URL}${encodeURIComponent(query)}`;
  const res = await fetchWithFallback(JINA_KEYS, (key) => 
    fetch(url, {
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${key}`,
        'X-With-Links-Summary': 'true',
        'X-Retain-Images': 'none',
      }
    })
  );

  if (!res.ok) throw new Error(`Jina Search final fail: ${res.status}`);
  const json = await res.json();
  return (json.data ?? []).slice(0, maxResults).map((item: any) => ({
    title: item.title ?? '',
    url: item.url ?? '',
    description: (item.description ?? item.content ?? '').slice(0, 800),
  }));
}

// ── Content Reading ──

async function readUrl(targetUrl: string) {
  const isYouTube = /youtube\.com|youtu\.be/.test(targetUrl);
  const url = `${JINA_READ_URL}${targetUrl}`;
  
  const res = await fetchWithFallback(JINA_KEYS, (key) => {
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      'Authorization': `Bearer ${key}`,
      'X-Return-Format': 'markdown',
    };
    if (isYouTube) {
      // 📹 Optimized YouTube Headers
      headers['X-With-Generated-Alt'] = 'true';
    } else {
      // 📄 Clean Web Page Headers
      headers['X-Remove-Selector'] = 'nav, footer, script, style, .ads, .sidebar, #comments, header, aside';
      headers['X-Target-Selector'] = 'main, article, .content, #content, body';
    }
    return fetch(url, { headers });
  });

  if (!res.ok) throw new Error(`Read error ${res.status}`);
  const json = await res.json();
  const data = json.data ?? {};
  let content: string = data.content ?? '';
  
  if (content.length > MAX_READ_CONTENT_LENGTH) {
    content = content.slice(0, MAX_READ_CONTENT_LENGTH) + '\n\n[... تم اختصار المحتوى لضمان جودة الأداء المتبقي ...]';
  }

  const prefix = isYouTube ? "### [محتوى فيديو يوتيوب - نص الحوار]\n\n" : "";
  return { 
    title: data.title ?? (isYouTube ? "YouTube Content" : ""), 
    url: data.url ?? targetUrl, 
    content: prefix + content 
  };
}

// ── Handler ──

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  try {
    const body = await req.json();
    const { action, query, url, max_results } = body;

    if (action === 'search') {
      try {
        const results = await searchWithTavily(query?.trim() || "", max_results ?? 5);
        return jsonResponse({ results, query, engine: 'tavily' });
      } catch (e) {
        console.warn(`Tavily failed (all keys), trying Jina: ${e.message}`);
        const results = await searchWithJina(query?.trim() || "", max_results ?? 5);
        return jsonResponse({ results, query, engine: 'jina' });
      }
    }

    if (action === 'read') return jsonResponse(await readUrl(url?.trim() || ""));

    return jsonResponse({ error: 'Invalid action' }, 400);
  } catch (err) {
    return jsonResponse({ error: err.message }, 500);
  }
});
