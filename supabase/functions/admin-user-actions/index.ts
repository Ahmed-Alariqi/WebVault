import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// Provide Deno global space for typescript IDE
declare const Deno: any;

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
            { auth: { autoRefreshToken: false, persistSession: false } }
        );

        const authHeader = req.headers.get("Authorization");
        if (!authHeader) throw new Error("Missing Authorization header");

        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
            authHeader.replace("Bearer ", "")
        );
        if (authError || !user) throw new Error("Invalid token");

        const { data: profile, error: profileError } = await supabaseClient
            .from("profiles").select("role").eq("id", user.id).single();

        if (profileError || profile?.role !== "admin") {
            return new Response(JSON.stringify({ error: "Unauthorized: Admin access required" }),
                { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        const { action, userId, email, password, role, fullName, permissions } = await req.json();
        let result;

        switch (action) {
            case "list_users": {
                const { data: users, error: listError } = await supabaseClient.auth.admin.listUsers();
                if (listError) throw listError;
                const userIds = users.users.map(u => u.id);
                const { data: profiles, error: profilesError } = await supabaseClient
                    .from("profiles").select("id, role, full_name, username, avatar_url, permissions").in("id", userIds);
                if (profilesError) throw profilesError;
                result = users.users.map(u => {
                    const p = profiles.find(prof => prof.id === u.id);
                    return {
                        id: u.id, email: u.email, created_at: u.created_at, last_sign_in_at: u.last_sign_in_at,
                        role: p?.role || "user", full_name: p?.full_name, username: p?.username,
                        avatar_url: p?.avatar_url, permissions: p?.permissions || []
                    };
                });
                break;
            }
            case "create_user": {
                if (!email || !password) throw new Error("Email and password are required");
                const { data: newUser, error: createError } = await supabaseClient.auth.admin.createUser({
                    email, password, email_confirm: true, user_metadata: { full_name: fullName }
                });
                if (createError) throw createError;
                if (newUser.user) {
                    const profileUpdates: any = {};
                    if (role) profileUpdates.role = role;
                    if (permissions) profileUpdates.permissions = permissions;
                    if (Object.keys(profileUpdates).length > 0) {
                        await supabaseClient.from("profiles").update(profileUpdates).eq("id", newUser.user.id);
                    }
                }
                result = newUser.user;
                break;
            }
            case "update_user": {
                if (!userId) throw new Error("User ID is required");
                const updates: any = {};
                if (email) updates.email = email;
                if (password) updates.password = password;
                if (Object.keys(updates).length > 0) {
                    const { error: updateAuthError } = await supabaseClient.auth.admin.updateUserById(userId, updates);
                    if (updateAuthError) throw updateAuthError;
                }
                const profileUpdates: any = {};
                if (role) profileUpdates.role = role;
                if (permissions !== undefined) profileUpdates.permissions = permissions;
                if (Object.keys(profileUpdates).length > 0) {
                    const { error: updateProfileError } = await supabaseClient.from("profiles").update(profileUpdates).eq("id", userId);
                    if (updateProfileError) throw updateProfileError;
                }
                result = { success: true };
                break;
            }
            case "delete_user": {
                if (!userId) throw new Error("User ID is required");
                const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(userId);
                if (deleteError) throw deleteError;
                result = { success: true };
                break;
            }
            default:
                throw new Error(`Unknown action: ${action}`);
        }

        return new Response(JSON.stringify(result),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
});
