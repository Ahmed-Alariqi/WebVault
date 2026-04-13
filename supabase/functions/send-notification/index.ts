import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
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
        const { title, body, type, target_url, image_url, created_by } = await req.json();

        if (!initFirebase()) {
            return new Response(
                JSON.stringify({ error: "Firebase configuration is missing or invalid. Check FCM_SERVICE_ACCOUNT_KEY secret." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Initialize Supabase Client
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

        // Fetch all active FCM tokens and names
        const { data: users, error } = await supabase
            .from('profiles')
            .select('fcm_token, full_name, username')
            .not('fcm_token', 'is', null);

        if (error) throw error;
        if (!users || users.length === 0) {
            return new Response(
                JSON.stringify({ message: "No registered devices found" }),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const messaging = getMessaging();
        const maxTokensPerBatch = 500;
        const results = [];

        // We process in loops to personalize each message with {user_name}
        // Since FCM multicast doesn't support message personalization, we must create an array of messages
        const messages = users.filter(u => u.fcm_token).map(user => {
            const userName = user.full_name || user.username || 'there';
            
            // Replace placeholder in title and body
            const personalizedTitle = (title || '').replace(/\{user_name\}/g, userName);
            const personalizedBody = (body || title || '').replace(/\{user_name\}/g, userName);

            return {
                token: user.fcm_token,
                notification: {
                    title: personalizedTitle,
                    body: personalizedBody,
                    ...(image_url ? { imageUrl: image_url } : {})
                },
                data: {
                    type: type || 'general',
                    target_url: target_url || '',
                    created_by: created_by || '',
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
        });

        // Send messages in batches of 500
        for (let i = 0; i < messages.length; i += maxTokensPerBatch) {
            const batch = messages.slice(i, i + maxTokensPerBatch);
            const batchResponse = await messaging.sendEach(batch);
            results.push(batchResponse);
            
            // Log any failures to edge function logs
            if (batchResponse.failureCount > 0) {
                batchResponse.responses.forEach((resp: any, idx: number) => {
                    if (!resp.success) {
                        console.error(`Failed to send to token ${batch[idx].token}:`, resp.error);
                    }
                });
            }
        }

        const totalSuccess = results.reduce((sum, res) => sum + res.successCount, 0);
        const totalFailure = results.reduce((sum, res) => sum + res.failureCount, 0);
        
        console.log(`FCM push complete. Success: ${totalSuccess}, Failed: ${totalFailure}`);

        return new Response(
            JSON.stringify({ 
                success: totalSuccess > 0 || messages.length === 0, 
                message: `Sent to ${totalSuccess} devices. Failed: ${totalFailure}` 
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    } catch (error: any) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
    }
});
