import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore
import { initializeApp, cert, getApps } from "npm:firebase-admin@12.0.0/app";
// @ts-ignore
import { getMessaging } from "npm:firebase-admin@12.0.0/messaging";

declare const Deno: any;

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Initialize Firebase Admin (cached across invocations)
function initFirebase() {
    if (getApps().length > 0) return true;
    try {
        const serviceAccountStr = Deno.env.get('FCM_SERVICE_ACCOUNT_KEY');
        if (!serviceAccountStr) throw new Error("FCM_SERVICE_ACCOUNT_KEY missing");
        const serviceAccount = JSON.parse(serviceAccountStr);
        
        initializeApp({
            credential: cert(serviceAccount as any),
        });
        return true;
    } catch (error) {
        console.error("Failed to initialize Firebase Admin:", error);
        return false;
    }
}

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { fcm_token } = await req.json();

        if (!fcm_token) {
            return new Response(
                JSON.stringify({ error: "Missing fcm_token" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        if (!initFirebase()) {
            return new Response(
                JSON.stringify({ error: "Firebase configuration is missing or invalid. Check FCM_SERVICE_ACCOUNT_KEY secret." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const messaging = getMessaging();

        const message = {
            token: fcm_token,
            notification: {
                title: "Notifications Active!",
                body: "You are now set up to receive notifications. The connection to FCM is secure and direct."
            },
            android: {
                priority: "high" as const,
                notification: {
                    channelId: "webvault_notifications",
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default"
                    }
                }
            }
        };

        const response = await messaging.send(message);

        return new Response(
            JSON.stringify({ success: true, messageId: response }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    } catch (error: any) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    }
});
