import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// Provide Deno global space for typescript IDE
declare const Deno: any;

const ONE_SIGNAL_API_URL = "https://onesignal.com/api/v1/notifications";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { title, body, type, target_url, created_by } = await req.json();

        const appId = Deno.env.get("ONESIGNAL_APP_ID");
        const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

        if (!appId || !apiKey) {
            return new Response(
                JSON.stringify({ error: "Missing OneSignal credentials. Set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY secrets." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const payload = {
            app_id: appId,
            included_segments: ["Subscribed Users", "Active Users"],
            headings: { en: title },
            contents: { en: body || title },
            data: { type, target_url, created_by },
        };

        const response = await fetch(ONE_SIGNAL_API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Basic ${apiKey}`,
            },
            body: JSON.stringify(payload),
        });

        const result = await response.json();

        return new Response(
            JSON.stringify(result),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    } catch (error: any) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    }
});
