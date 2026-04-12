import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// Provide Deno global space for typescript IDE
declare const Deno: any;

Deno.serve(async (req: Request) => {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
        auth: { autoRefreshToken: false, persistSession: false }
    });

    const { data, error } = await adminClient.auth.admin.createUser({
        email: 'test@webvault.app',
        password: 'Test1234!',
        email_confirm: true,
        user_metadata: { full_name: 'Test User', username: 'tester' }
    });

    if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 400, headers: { 'Content-Type': 'application/json' }
        });
    }

    if (data.user) {
        await adminClient.from('profiles').update({
            full_name: 'Test User', username: 'tester', role: 'admin'
        }).eq('id', data.user.id);
    }

    return new Response(JSON.stringify({
        message: 'Test user created!',
        email: 'test@webvault.app',
        password: 'Test1234!',
        userId: data.user?.id
    }), { headers: { 'Content-Type': 'application/json' } });
});
