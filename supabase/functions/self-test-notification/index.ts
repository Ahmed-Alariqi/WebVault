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
        const { player_id } = await req.json();

        if (!player_id) {
            return new Response(
                JSON.stringify({ error: "Missing player_id" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const appId = Deno.env.get("ONESIGNAL_APP_ID");
        const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

        if (!appId || !apiKey) {
            return new Response(
                JSON.stringify({ error: "Missing OneSignal credentials." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const payload: Record<string, any> = {
            app_id: appId,
            include_player_ids: [player_id], // Targets specifically this ONE device
            headings: { en: "Notifications Active!" },
            contents: { en: "You are now set up to receive notifications. The connection is secure." },

            // ── Android: force heads-up / status bar display ──
            priority: 10,
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
