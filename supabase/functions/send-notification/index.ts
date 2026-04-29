import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore - Deno JSR import not recognized by standard TS server
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
        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
            return new Response(JSON.stringify({ error: "Missing Auth Header" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
        const supabaseAuthClient = createClient(supabaseUrl, supabaseAnonKey);
        
        const { data: { user }, error: authError } = await supabaseAuthClient.auth.getUser(authHeader.replace("Bearer ", ""));
        if (authError || !user) {
             return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        const reqBody = await req.json();
        const {
            title,
            body,
            type,
            target_url,
            image_url,
            created_by,
            // New fields for unified routing:
            mode = 'broadcast',                 // 'broadcast' | 'auto_content_only' | 'chat_to_admins' | 'chat_to_user'
            target_user_id,                     // required for mode='chat_to_user'
            sender_id,                          // for chat modes — used to fetch sender name
            conversation_id,                    // for chat modes — used as Android tag (coalesce)
        } = reqBody;

        if (!initFirebase()) {
            return new Response(
                JSON.stringify({ error: "Firebase configuration is missing or invalid. Check FCM_SERVICE_ACCOUNT_KEY secret." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Initialize Supabase Admin Client for DB queries
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

        // ── Build the recipient query per mode ──────────────────────────
        // All modes share these gates: token present, token not invalidated, master push on.
        let query = supabase
            .from('profiles')
            .select('id, fcm_token, full_name, username')
            .not('fcm_token', 'is', null)
            .is('fcm_token_invalid_at', null)
            .eq('notif_push_enabled', true);

        if (mode === 'auto_content_only') {
            query = query.eq('notif_all_new_content', true);
        } else if (mode === 'chat_to_admins') {
            query = query.eq('notif_chat', true).eq('role', 'admin');
            if (sender_id) query = query.neq('id', sender_id); // don't push the sender themselves
        } else if (mode === 'chat_to_user') {
            if (!target_user_id) {
                return new Response(
                    JSON.stringify({ error: "target_user_id required for mode=chat_to_user" }),
                    { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
                );
            }
            query = query.eq('notif_chat', true).eq('id', target_user_id);
        }
        // mode === 'broadcast' → no extra filter

        const { data: users, error } = await query;

        if (error) throw error;
        if (!users || users.length === 0) {
            return new Response(
                JSON.stringify({
                    message: "No registered devices found",
                    sent_count: 0, failed_count: 0, total_targeted: 0, invalidated_count: 0,
                }),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // ── For chat modes, fetch sender's display name to prefix the title ──
        let chatSenderName = '';
        const isChatMode = mode === 'chat_to_admins' || mode === 'chat_to_user';
        if (isChatMode && sender_id) {
            const { data: sender } = await supabase
                .from('profiles')
                .select('full_name, username')
                .eq('id', sender_id)
                .maybeSingle();
            if (sender) {
                chatSenderName = (sender as any).full_name || (sender as any).username || '';
            }
        }

        const messaging = getMessaging();
        const maxTokensPerBatch = 500;
        const results = [];

        // Build personalized messages
        const messages = users.filter((u: any) => u.fcm_token).map((user: any) => {
            const userName = user.full_name || user.username || 'there';

            // Replace {user_name} placeholder in title/body
            let finalTitle = (title || '').replace(/\{user_name\}/g, userName);
            const finalBody = (body || title || '').replace(/\{user_name\}/g, userName);

            // For chat: prefix sender name to title — "أحمد: مرحباً ..."
            if (isChatMode && chatSenderName) {
                finalTitle = `${chatSenderName}: ${finalTitle || finalBody}`.slice(0, 120);
            }

            const dataPayload: Record<string, string> = {
                type: type || (isChatMode ? 'chat' : 'general'),
                target_url: target_url || '',
                created_by: created_by || '',
            };
            if (conversation_id) dataPayload.conversation_id = String(conversation_id);
            if (sender_id) dataPayload.sender_id = String(sender_id);

            const androidNotif: Record<string, any> = {
                channelId: "webvault_notifications",
            };
            // Coalesce repeated chat messages of the same conversation into one notification
            if (isChatMode && conversation_id) {
                androidNotif.tag = `chat_${conversation_id}`;
            }

            const apnsPayload: Record<string, any> = {
                aps: { sound: "default" },
            };
            if (isChatMode && conversation_id) {
                // iOS coalescing via thread-id
                apnsPayload.aps['thread-id'] = `chat_${conversation_id}`;
            }

            return {
                token: user.fcm_token,
                notification: {
                    title: finalTitle,
                    body: finalBody,
                    ...(image_url ? { imageUrl: image_url } : {})
                },
                data: dataPayload,
                android: {
                    priority: "high" as const,
                    notification: androidNotif,
                },
                apns: { payload: apnsPayload },
            };
        });

        // Send messages in batches of 500 — track per-token success/failure
        const successTokens: string[] = [];
        const invalidatedTokens: string[] = [];

        for (let i = 0; i < messages.length; i += maxTokensPerBatch) {
            const batch = messages.slice(i, i + maxTokensPerBatch);
            const batchResponse = await messaging.sendEach(batch);
            results.push(batchResponse);

            batchResponse.responses.forEach((resp: any, idx: number) => {
                const tok = batch[idx].token;
                if (resp.success) {
                    successTokens.push(tok);
                } else {
                    const code = resp.error?.code || '';
                    console.error(`Failed to send to token ${tok}:`, resp.error);
                    if (code === 'messaging/registration-token-not-registered' ||
                        code === 'messaging/invalid-registration-token' ||
                        code === 'messaging/invalid-argument') {
                        invalidatedTokens.push(tok);
                    }
                }
            });
        }

        // ── Mark dead tokens (uninstalls) for stats — keep the token value for traceability ──
        if (invalidatedTokens.length > 0) {
            try {
                await supabase
                    .from('profiles')
                    .update({ fcm_token_invalid_at: new Date().toISOString() })
                    .in('fcm_token', invalidatedTokens);
            } catch (e) {
                console.error('Failed to mark invalid tokens:', e);
            }
        }

        // ── Stamp last successful delivery time ──
        if (successTokens.length > 0) {
            try {
                await supabase
                    .from('profiles')
                    .update({ fcm_last_success_at: new Date().toISOString() })
                    .in('fcm_token', successTokens);
            } catch (e) {
                console.error('Failed to update fcm_last_success_at:', e);
            }
        }

        const totalSuccess = results.reduce((sum, res) => sum + res.successCount, 0);
        const totalFailure = results.reduce((sum, res) => sum + res.failureCount, 0);

        console.log(`FCM push (mode=${mode}) complete. Success: ${totalSuccess}, Failed: ${totalFailure}, Invalidated: ${invalidatedTokens.length}`);

        return new Response(
            JSON.stringify({
                success: totalSuccess > 0 || messages.length === 0,
                message: `Sent to ${totalSuccess} devices. Failed: ${totalFailure}`,
                sent_count: totalSuccess,
                failed_count: totalFailure,
                total_targeted: messages.length,
                invalidated_count: invalidatedTokens.length,
                mode,
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
