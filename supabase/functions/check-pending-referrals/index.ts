import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// Provide Deno global space for typescript IDE
declare const Deno: any;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const GRACE_PERIOD_DAYS = 3;
const REQUIRED_APP_OPENS = 3;
const CONTENT_ACTIVITY_TYPES = ["item_view", "clipboard_add", "page_add", "search", "bookmark"];

Deno.serve(async (_req: Request) => {
    try {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
        const { data: pendingReferrals, error: fetchError } = await supabase
            .from("referrals").select("id, referred_id, campaign_id, created_at").eq("status", "pending");

        if (fetchError) return new Response(JSON.stringify({ error: fetchError.message }), { status: 500, headers: { "Content-Type": "application/json" } });
        if (!pendingReferrals || pendingReferrals.length === 0) return new Response(JSON.stringify({ message: "No pending referrals to process" }), { status: 200, headers: { "Content-Type": "application/json" } });

        const now = new Date();
        let expired = 0, confirmed = 0, stillPending = 0;

        for (const referral of pendingReferrals) {
            const createdAt = new Date(referral.created_at);
            const deadline = new Date(createdAt.getTime() + GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000);

            if (now > deadline) {
                const isActive = await checkUserActivity(supabase, referral.referred_id, referral.created_at);
                if (isActive) {
                    await supabase.from("referrals").update({ status: "confirmed", confirmed_at: now.toISOString(), verified_at: now.toISOString() }).eq("id", referral.id);
                    await processRewards(supabase, referral.referred_id, referral.campaign_id);
                    confirmed++;
                } else {
                    await supabase.from("referrals").update({ status: "expired" }).eq("id", referral.id);
                    expired++;
                }
            } else {
                const isActive = await checkUserActivity(supabase, referral.referred_id, referral.created_at);
                if (isActive) {
                    await supabase.from("referrals").update({ status: "confirmed", confirmed_at: now.toISOString(), verified_at: now.toISOString() }).eq("id", referral.id);
                    await processRewards(supabase, referral.referred_id, referral.campaign_id);
                    confirmed++;
                } else { stillPending++; }
            }
        }

        return new Response(JSON.stringify({ processed: pendingReferrals.length, confirmed, expired, stillPending }), { status: 200, headers: { "Content-Type": "application/json" } });
    } catch (err) {
        return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
});

async function checkUserActivity(supabase: ReturnType<typeof createClient>, userId: string, referralCreatedAt: string): Promise<boolean> {
    const { data: profile } = await supabase.from("profiles").select("full_name, username").eq("id", userId).single();
    if (!profile?.full_name || !profile?.username) return false;
    const { data: appOpens } = await supabase.from("user_activity").select("id").eq("user_id", userId).eq("activity_type", "app_open").gte("created_at", referralCreatedAt);
    if (!appOpens || appOpens.length < REQUIRED_APP_OPENS) return false;
    const { data: contentActs } = await supabase.from("user_activity").select("id").eq("user_id", userId).in("activity_type", CONTENT_ACTIVITY_TYPES).gte("created_at", referralCreatedAt).limit(1);
    if (!contentActs || contentActs.length === 0) return false;
    return true;
}

async function processRewards(supabase: ReturnType<typeof createClient>, referredId: string, campaignId: string): Promise<void> {
    const { data: campaign } = await supabase.from("referral_campaigns").select("*").eq("id", campaignId).single();
    if (!campaign) return;
    if (campaign.referred_reward_type === "giveaway_entry" && campaign.reward_giveaway_id) {
        try { await supabase.from("giveaway_entries").insert({ giveaway_id: campaign.reward_giveaway_id, user_id: referredId }); } catch { }
    }
    const { data: referral } = await supabase.from("referrals").select("referrer_id").eq("referred_id", referredId).eq("campaign_id", campaignId).single();
    if (!referral) return;
    const { data: confirmedRefs } = await supabase.from("referrals").select("id").eq("referrer_id", referral.referrer_id).eq("campaign_id", campaignId).eq("status", "confirmed");
    if (confirmedRefs && confirmedRefs.length >= campaign.required_referrals) {
        if (campaign.reward_type === "giveaway_entry" && campaign.reward_giveaway_id) {
            try { await supabase.from("giveaway_entries").insert({ giveaway_id: campaign.reward_giveaway_id, user_id: referral.referrer_id }); } catch { }
        }
    }
}
