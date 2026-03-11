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
        const { title, body, type, target_url, image_url, created_by } = await req.json();

        const appId = Deno.env.get("ONESIGNAL_APP_ID");
        const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

        if (!appId || !apiKey) {
            return new Response(
                JSON.stringify({ error: "Missing OneSignal credentials. Set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY secrets." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Convert {user_name} placeholder to OneSignal Liquid template syntax
        // so it gets replaced with the actual user tag on the device lock screen
        const osTitleText = (title || '').replace(/\{user_name\}/g, "{{ user_name | default: 'there' }}");
        const osBodyText = (body || title || '').replace(/\{user_name\}/g, "{{ user_name | default: 'there' }}");

        const payload: Record<string, any> = {
            app_id: appId,
            // "Total Subscriptions" is the default segment that includes ALL opted-in users
            included_segments: ["Total Subscriptions"],
            headings: { en: osTitleText },
            contents: { en: osBodyText },
            data: { type, target_url, image_url, created_by },
            // ── Imagery ──
            ...(image_url ? { big_picture: image_url, ios_attachments: { id1: image_url } } : {}),
            // ── Android: force heads-up / status bar display ──
            priority: 10,                          // FCM high priority
            android_group: "webvault_notifications",
            // ── iOS ──
            ios_sound: "default",
            // ── General ──
            isAndroid: true,
            isIos: true,
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
