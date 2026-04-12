# WebVault (زاد التقني) — Supabase Infrastructure Blueprint
## وثيقة استعادة شاملة للكوارث والترحيل

> **الغرض:** هذه الوثيقة تحتوي كل ما يلزم لإعادة بناء البنية التحتية لـ Supabase من الصفر على مشروع جديد. أعطِ هذه الوثيقة + كود GitHub لأي وكيل ذكي أو مطور وسيتمكن من إعادة بناء 100% من الهيكل.
> 
> **آخر تحديث:** 2026-04-12
> 
> **Project ID:** `poepodtageytnzucrsmg`

---

## جدول المحتويات
1. [نظرة عامة](#1-نظرة-عامة)
2. [الإضافات المطلوبة (Extensions)](#2-الإضافات-المطلوبة)
3. [جداول قاعدة البيانات](#3-جداول-قاعدة-البيانات)
4. [سياسات الأمان RLS الكاملة](#4-سياسات-الأمان-rls)
5. [الدوال المخزنة PL/pgSQL (الكود الكامل)](#5-الدوال-المخزنة)
6. [المشغلات Triggers](#6-المشغلات)
7. [الفهارس المخصصة Indexes](#7-الفهارس-المخصصة)
8. [Realtime (البث المباشر)](#8-realtime)
9. [المهام المجدولة Cron Jobs](#9-المهام-المجدولة)
10. [حاويات التخزين Storage Buckets](#10-حاويات-التخزين)
11. [Edge Functions (7 وظائف)](#11-edge-functions)
12. [المتغيرات السرية Secrets](#12-المتغيرات-السرية)
13. [إعداد المصادقة Authentication](#13-إعداد-المصادقة)
14. [تحديث تطبيق Flutter](#14-تحديث-تطبيق-flutter)
15. [ما يجب استخراجه يدوياً ⚠️](#15-ما-يجب-استخراجه-يدوياً)
16. [خطوات إعادة البناء الكاملة](#16-خطوات-إعادة-البناء)
17. [تصدير/استيراد البيانات](#17-تصدير-البيانات)

---

## 1. نظرة عامة

| المفتاح | القيمة |
|---------|--------|
| Project ID | `poepodtageytnzucrsmg` |
| Auth Provider | Email/Password |
| Push Notifications | OneSignal |
| AI/LLM Provider | Ollama API (cloud models via `https://ollama.com/api/chat`) |
| URL Scraper | Jina AI Reader (`https://r.jina.ai/`) |
| Default LLM Model | `gemini-3-flash-preview:cloud` |
| عدد الجداول | 30 |
| عدد الـ Migrations | 38 |
| عدد الـ Edge Functions | 7 |
| عدد الـ RLS Policies | 80+ |
| عدد الـ PL/pgSQL Functions | 11 |

---

## 2. الإضافات المطلوبة

```sql
-- يجب تفعيلها على المشروع الجديد
CREATE EXTENSION IF NOT EXISTS "pg_cron" SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_net" SCHEMA extensions;
-- pgvector مثبت لكن غير مستخدم حالياً (للبحث الدلالي مستقبلاً)
```

---

## 3. جداول قاعدة البيانات

### الـ Migrations بالترتيب (38 ملف)

| # | Version | Name |
|---|---------|------|
| 1 | 20260216151809 | create_profiles_table |
| 2 | 20260216151822 | create_categories_table |
| 3 | 20260216151824 | create_websites_table |
| 4 | 20260216151839 | create_tools_table |
| 5 | 20260216151842 | create_notifications_table |
| 6 | 20260216151844 | create_user_saved_websites_table |
| 7 | 20260216151903 | create_user_sync_tables |
| 8 | 20260218223643 | create_page_suggestions_table |
| 9 | 20260223145408 | create_chat_tables |
| 10 | 20260224193032 | delete_chat_admin_rpc |
| 11 | 20260224195506 | fix_avatar_storage_rls |
| 12 | 20260225115044 | add_in_app_message_columns |
| 13 | 20260226191546 | add_discover_content_types |
| 14 | 20260226203252 | add_show_every_time_to_in_app_messages |
| 15 | 20260226215018 | create_discover_bookmarks_table |
| 16 | 20260227000129 | add_video_url_to_websites |
| 17 | 20260228001405 | add_community_tables |
| 18 | 20260228204140 | community_bug_fixes |
| 19 | 20260308192353 | add_personalize_name_to_in_app_messages |
| 20 | 20260308193844 | add_personalize_name_to_notifications |
| 21 | 20260310020754 | add_delete_policy_for_notifications |
| 22 | 20260311200231 | create_advertisements_table |
| 23 | 20260313004721 | add_permissions_system |
| 24 | 20260313012453 | rls_permissions_fix |
| 25 | 20260314182749 | discover_enhancements_2 |
| 26 | 20260330135716 | create_featured_collections |
| 27 | 20260330192958 | categories_multi_content_types |
| 28 | 20260331190014 | add_ad_detail_card_fields |
| 29 | 20260401160716 | create_app_settings_and_community_columns |
| 30 | 20260401210823 | create_giveaways_tables |
| 31 | 20260401210828 | create_polls_tables |
| 32 | 20260402180457 | interactive_giveaway_features |
| 33 | 20260403175408 | add_username_changed_at |
| 34 | 20260404211856 | create_referral_system |
| 35 | 20260407162308 | fix_handle_new_user_trigger_add_username |
| 36 | 20260407162313 | add_verified_at_to_referrals |
| 37 | 20260407162719 | setup_referral_cron_job |
| 38 | 20260411121319 | add_expired_status_to_referrals |

### ملخص الجداول (30 جدول)

| الجدول | RLS | العلاقات الرئيسية |
|--------|-----|-------------------|
| profiles | ✅ | → auth.users.id |
| categories | ✅ | — |
| websites | ✅ | → categories, → profiles |
| tools | ✅ | → profiles |
| notifications | ✅ | → profiles |
| user_saved_websites | ✅ | → profiles, → websites |
| user_pages | ✅ | → profiles |
| user_folders | ✅ | → profiles |
| user_clipboard | ✅ | → profiles |
| page_suggestions | ✅ | → auth.users |
| in_app_messages | ✅ | — |
| conversations | ✅ | → profiles |
| messages | ✅ | → conversations, → profiles |
| discover_bookmarks | ✅ | → auth.users, → websites |
| user_activity | ✅ | → profiles |
| item_views | ✅ | → profiles, → websites |
| community_posts | ✅ | → profiles |
| community_replies | ✅ | → profiles, → community_posts |
| community_reactions | ✅ | → profiles, → community_posts |
| advertisements | ✅ | — |
| featured_collections | ✅ | — |
| collection_items | ✅ | → featured_collections, → websites |
| app_settings | ✅ | — |
| giveaways | ✅ | → profiles |
| giveaway_entries | ✅ | → giveaways, → profiles |
| polls | ✅ | → profiles |
| poll_votes | ✅ | → polls, → profiles |
| referral_campaigns | ✅ | → profiles, → giveaways, → featured_collections |
| referral_codes | ✅ | → profiles |
| referrals | ✅ | → profiles, → referral_campaigns |

### أعمدة الجداول الرئيسية

#### profiles
```
id UUID PK (FK → auth.users.id ON DELETE CASCADE)
full_name TEXT DEFAULT ''
username TEXT UNIQUE NULLABLE
avatar_url TEXT NULLABLE
role TEXT DEFAULT 'user' CHECK (IN ('user', 'admin', 'content_creator'))
onesignal_player_id TEXT NULLABLE
email TEXT NULLABLE
permissions TEXT[] DEFAULT '{}'
community_ban_type TEXT NULLABLE CHECK (IN ('mute', 'ban'))
community_ban_expires_at TIMESTAMPTZ NULLABLE
community_banned_by UUID NULLABLE
username_changed_at TIMESTAMPTZ NULLABLE
referred_by UUID NULLABLE (FK → profiles.id)
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

#### websites
```
id UUID PK DEFAULT gen_random_uuid()
title TEXT NOT NULL
url TEXT DEFAULT ''
description TEXT DEFAULT ''
image_url TEXT NULLABLE
tags TEXT[] DEFAULT '{}'
category_id UUID NULLABLE (FK → categories.id)
is_trending BOOLEAN DEFAULT false
is_popular BOOLEAN DEFAULT false
is_featured BOOLEAN DEFAULT false
created_by UUID NULLABLE (FK → profiles.id)
content_type TEXT DEFAULT 'website'
action_value TEXT DEFAULT ''
expires_at TIMESTAMPTZ NULLABLE
is_active BOOLEAN DEFAULT true
video_url TEXT NULLABLE
pricing_model TEXT DEFAULT 'free' NULLABLE
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

#### categories
```
id UUID PK DEFAULT gen_random_uuid()
name TEXT UNIQUE NOT NULL
icon_code_point INTEGER DEFAULT 983044
color_value INTEGER DEFAULT 4282339765
sort_order INTEGER DEFAULT 0
content_types TEXT[] NULLABLE
created_at TIMESTAMPTZ DEFAULT now()
```

---

## 4. سياسات الأمان RLS

> **هام:** جميع الجداول مفعّل عليها RLS. جميع السياسات PERMISSIVE.

### دالة الصلاحيات المساعدة
كل السياسات تستخدم `has_permission()` — انظر القسم 5.

### profiles
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view profiles | SELECT | `true` |
| Users can insert own profile | INSERT | `auth.uid() = id` |
| Users can update own profile | UPDATE | `auth.uid() = id` |

### websites
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view websites | SELECT | `true` |
| Users with websites perm can manage | ALL | `has_permission('websites')` |

### categories
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view categories | SELECT | `true` |
| Users with categories perm can manage | ALL | `has_permission('categories')` |

### notifications
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view notifications | SELECT | `true` |
| Users with notifications perm can manage | ALL | `has_permission('notifications')` |

### advertisements
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Public can view | SELECT | `true` |
| Users with advertisements perm | ALL | `has_permission('advertisements')` |

### conversations
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users can view own | SELECT | `auth.uid() = user_id` |
| Users can insert own | INSERT | `auth.uid() = user_id` |
| Users can update own | UPDATE | `auth.uid() = user_id` |
| Users/community perm | ALL | `has_permission('users') OR has_permission('community')` |

### messages
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users can view own | SELECT | conversation belongs to user |
| Users can insert own | INSERT | conversation belongs to user |
| Users can update own | UPDATE | sender_id + conversation belongs to user |
| Users/community perm | ALL | `has_permission('users') OR has_permission('community')` |

### community_posts
| السياسة | العملية | الشرط |
|---------|---------|-------|
| View unarchived or admin | SELECT | `is_archived = false OR has_permission('community')` |
| Users insert own | INSERT | `auth.uid() = user_id` |
| Users update own | UPDATE | `auth.uid() = user_id` |
| Community perm update | UPDATE | `has_permission('community')` |
| Users/admin delete | DELETE | `auth.uid() = user_id OR has_permission('community')` |

### community_replies
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view | SELECT | `true` |
| Users insert own | INSERT | `auth.uid() = user_id` |
| Users update own | UPDATE | `auth.uid() = user_id` |
| Users/admin delete | DELETE | `auth.uid() = user_id OR has_permission('community')` |

### community_reactions
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view | SELECT | `true` |
| Users insert own | INSERT | `auth.uid() = user_id` |
| Users delete own | DELETE | `auth.uid() = user_id` |

### user_saved_websites / user_pages / user_folders / user_clipboard
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users manage own | ALL | `auth.uid() = user_id` |

### discover_bookmarks
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users view/insert/delete own | SELECT/INSERT/DELETE | `auth.uid() = user_id` |

### page_suggestions
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users view/insert own | SELECT/INSERT | `auth.uid() = user_id` |
| Suggestions perm view/update/delete | SELECT/UPDATE/DELETE | `has_permission('suggestions')` |

### item_views / user_activity
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users insert own | INSERT | `auth.uid() = user_id` |
| Admins can view all | SELECT | role = admin |

### in_app_messages
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Allow admin all access | ALL | authenticated |
| Allow authenticated full access | ALL | `true` (role: authenticated) |
| Allow authenticated read | SELECT | `true` (role: authenticated) |
| Allow authenticated read access | SELECT | authenticated (role: public) |

### giveaways / polls
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view | SELECT | `true` |
| Admin/content_creator manage | INSERT/UPDATE/DELETE | role IN ('admin', 'content_creator') |

### giveaway_entries / poll_votes
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can view | SELECT | `true` |
| Users insert own | INSERT | `auth.uid() = user_id` |
| Users/admin delete | DELETE | own or admin |

### featured_collections / collection_items
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can read | SELECT | `true` |
| Admins can manage | ALL | `has_permission('websites')` |

### app_settings
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can read | SELECT | `true` |
| Admins can update | UPDATE | role = admin |

### referral_campaigns
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can read | SELECT | `true` |
| Admins manage | INSERT/UPDATE/DELETE | role = admin |

### referral_codes
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Anyone can read | SELECT | `true` |
| Users insert own | INSERT | `user_id = auth.uid()` |

### referrals
| السياسة | العملية | الشرط |
|---------|---------|-------|
| Users read own or admin | SELECT | referrer/referred = uid OR admin |
| Users insert own | INSERT | `referred_id = auth.uid()` |
| Admins can update | UPDATE | role = admin |

---

## 5. الدوال المخزنة (الكود الكامل)

### handle_new_user() → TRIGGER
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'username',
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = COALESCE(EXCLUDED.username, profiles.username);
  RETURN NEW;
END;
$function$;
```

### has_permission(required_permission TEXT) → BOOLEAN
```sql
CREATE OR REPLACE FUNCTION public.has_permission(required_permission text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_role text;
    user_permissions text[];
BEGIN
    SELECT role, permissions INTO user_role, user_permissions
    FROM public.profiles
    WHERE id = auth.uid();

    IF user_role = 'admin' THEN RETURN true; END IF;

    IF user_role = 'content_creator' THEN
        IF required_permission = ANY(ARRAY['websites', 'categories', 'notifications', 'suggestions', 'community', 'users']) THEN
            RETURN true;
        END IF;
    END IF;

    IF user_permissions IS NOT NULL AND required_permission = ANY(user_permissions) THEN
        RETURN true;
    END IF;

    RETURN false;
END;
$function$;
```

### update_updated_at() → TRIGGER
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;
```

### delete_chat_admin(conv_id UUID) → VOID
```sql
CREATE OR REPLACE FUNCTION public.delete_chat_admin(conv_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  DELETE FROM messages WHERE conversation_id = conv_id;
  DELETE FROM conversations WHERE id = conv_id;
END;
$function$;
```

### increment_reply_count(p_post_id UUID, p_amount INT) → VOID
```sql
CREATE OR REPLACE FUNCTION public.increment_reply_count(p_post_id uuid, p_amount integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE community_posts
  SET replies_count = GREATEST(0, COALESCE(replies_count, 0) + p_amount)
  WHERE id = p_post_id;
END;
$function$;
```

### toggle_community_reaction(p_post_id UUID, p_user_id UUID, p_emoji TEXT) → VOID
```sql
CREATE OR REPLACE FUNCTION public.toggle_community_reaction(p_post_id uuid, p_user_id uuid, p_emoji text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_exists BOOLEAN;
  v_current_reactions JSONB;
  v_current_count INT;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM community_reactions
    WHERE post_id = p_post_id AND user_id = p_user_id AND emoji = p_emoji
  ) INTO v_exists;

  SELECT reactions INTO v_current_reactions FROM community_posts WHERE id = p_post_id;
  IF v_current_reactions IS NULL THEN v_current_reactions := '{}'::jsonb; END IF;
  v_current_count := COALESCE((v_current_reactions->>p_emoji)::int, 0);

  IF v_exists THEN
    DELETE FROM community_reactions
    WHERE post_id = p_post_id AND user_id = p_user_id AND emoji = p_emoji;
    v_current_count := v_current_count - 1;
    IF v_current_count <= 0 THEN
      v_current_reactions := v_current_reactions - p_emoji;
    ELSE
      v_current_reactions := jsonb_set(v_current_reactions, ARRAY[p_emoji], to_jsonb(v_current_count));
    END IF;
  ELSE
    INSERT INTO community_reactions (post_id, user_id, emoji)
    VALUES (p_post_id, p_user_id, p_emoji);
    v_current_count := v_current_count + 1;
    v_current_reactions := jsonb_set(v_current_reactions, ARRAY[p_emoji], to_jsonb(v_current_count));
  END IF;

  UPDATE community_posts SET reactions = v_current_reactions WHERE id = p_post_id;
END;
$function$;
```

### wipe_community_chat() → VOID
```sql
CREATE OR REPLACE FUNCTION public.wipe_community_chat()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  DELETE FROM community_replies WHERE true;
  DELETE FROM community_reactions WHERE true;
  DELETE FROM community_posts WHERE true;
END;
$function$;
```

### cleanup_old_analytics(days_to_keep INT) → VOID
```sql
CREATE OR REPLACE FUNCTION public.cleanup_old_analytics(days_to_keep integer DEFAULT 15)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  DELETE FROM public.item_views
  WHERE created_at < NOW() - (days_to_keep || ' days')::interval;
  DELETE FROM public.user_activity
  WHERE created_at < NOW() - (days_to_keep || ' days')::interval;
END;
$function$;
```

### get_daily_active_users(days INT) → TABLE
```sql
CREATE OR REPLACE FUNCTION public.get_daily_active_users(days integer)
 RETURNS TABLE(date date, count integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    date(created_at) AS date,
    count(DISTINCT user_id)::int AS count
  FROM public.user_activity
  WHERE created_at >= (now() - (days || ' days')::interval)
  GROUP BY date(created_at)
  ORDER BY date(created_at) ASC;
END;
$function$;
```

### get_top_searches(days_limit INT, result_limit INT) → TABLE
```sql
CREATE OR REPLACE FUNCTION public.get_top_searches(days_limit integer DEFAULT 15, result_limit integer DEFAULT 10)
 RETURNS TABLE(query text, search_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    (metadata->>'query')::TEXT as query,
    COUNT(*) as search_count
  FROM public.user_activity
  WHERE activity_type = 'search'
    AND metadata->>'query' IS NOT NULL
    AND TRIM(metadata->>'query') != ''
    AND created_at >= NOW() - (days_limit || ' days')::interval
  GROUP BY metadata->>'query'
  ORDER BY search_count DESC
  LIMIT result_limit;
END;
$function$;
```

### get_unique_active_users_count(start_date TEXT) → INTEGER
```sql
CREATE OR REPLACE FUNCTION public.get_unique_active_users_count(start_date text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  result int;
BEGIN
  SELECT count(DISTINCT user_id) INTO result
  FROM public.user_activity
  WHERE created_at >= start_date::timestamptz;
  RETURN result;
END;
$function$;
```

---

## 6. المشغلات (Triggers)

| المشغل | الجدول | الحدث | الدالة |
|--------|--------|-------|--------|
| on_auth_user_created | **auth.users** | AFTER INSERT | handle_new_user() |
| profiles_updated_at | profiles | BEFORE UPDATE | update_updated_at() |
| websites_updated_at | websites | BEFORE UPDATE | update_updated_at() |
| tools_updated_at | tools | BEFORE UPDATE | update_updated_at() |
| featured_collections_updated_at | featured_collections | BEFORE UPDATE | update_updated_at() |
| user_pages_updated_at | user_pages | BEFORE UPDATE | update_updated_at() |
| user_folders_updated_at | user_folders | BEFORE UPDATE | update_updated_at() |
| user_clipboard_updated_at | user_clipboard | BEFORE UPDATE | update_updated_at() |

> **تحذير:** المشغل `on_auth_user_created` مبني على جدول `auth.users` (وليس public):
> ```sql
> CREATE TRIGGER on_auth_user_created
>   AFTER INSERT ON auth.users
>   FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
> ```

---

## 7. الفهارس المخصصة (Indexes)

```sql
CREATE UNIQUE INDEX categories_name_key ON public.categories USING btree (name);
CREATE UNIQUE INDEX profiles_username_key ON public.profiles USING btree (username);
CREATE UNIQUE INDEX one_conversation_per_user ON public.conversations USING btree (user_id);
CREATE UNIQUE INDEX user_saved_websites_user_id_website_id_key ON public.user_saved_websites USING btree (user_id, website_id);
CREATE UNIQUE INDEX discover_bookmarks_user_id_website_id_key ON public.discover_bookmarks USING btree (user_id, website_id);
CREATE INDEX idx_discover_bookmarks_user ON public.discover_bookmarks USING btree (user_id);
CREATE INDEX idx_discover_bookmarks_website ON public.discover_bookmarks USING btree (website_id);
CREATE UNIQUE INDEX collection_items_collection_id_website_id_key ON public.collection_items USING btree (collection_id, website_id);
CREATE UNIQUE INDEX community_reactions_post_id_user_id_emoji_key ON public.community_reactions USING btree (post_id, user_id, emoji);
CREATE UNIQUE INDEX giveaway_entries_giveaway_id_user_id_key ON public.giveaway_entries USING btree (giveaway_id, user_id);
CREATE UNIQUE INDEX poll_votes_poll_id_user_id_selected_option_key ON public.poll_votes USING btree (poll_id, user_id, selected_option);
CREATE UNIQUE INDEX referral_codes_code_key ON public.referral_codes USING btree (code);
CREATE UNIQUE INDEX referral_codes_user_id_key ON public.referral_codes USING btree (user_id);
CREATE INDEX idx_referral_codes_code ON public.referral_codes USING btree (code);
CREATE INDEX idx_referrals_referrer ON public.referrals USING btree (referrer_id);
CREATE INDEX idx_referrals_campaign ON public.referrals USING btree (campaign_id);
CREATE UNIQUE INDEX referrals_referred_id_key ON public.referrals USING btree (referred_id);
```

---

## 8. Realtime (البث المباشر)

الجداول المضافة إلى `supabase_realtime` publication:

```sql
-- يجب إضافة هذه الجداول للـ Realtime على المشروع الجديد
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.community_replies;
ALTER PUBLICATION supabase_realtime ADD TABLE public.community_reactions;
```

---

## 9. المهام المجدولة (Cron Jobs)

| اسم المهمة | الجدول | الأمر |
|------------|--------|-------|
| check-pending-referrals | `0 */6 * * *` (كل 6 ساعات) | HTTP POST → Edge Function |
| cleanup_analytics_daily | `0 0 * * *` (يومياً منتصف الليل) | `SELECT public.cleanup_old_analytics(15)` |

```sql
-- 1) فحص الإحالات المعلقة
SELECT cron.schedule(
  'check-pending-referrals',
  '0 */6 * * *',
  $$
  SELECT net.http_post(
    url := '<SUPABASE_URL>/functions/v1/check-pending-referrals',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- 2) تنظيف التحليلات القديمة
SELECT cron.schedule(
  'cleanup_analytics_daily',
  '0 0 * * *',
  $$ SELECT public.cleanup_old_analytics(15); $$
);
```

---

## 10. حاويات التخزين (Storage Buckets)

| الحاوية | عامة | الاستخدام |
|---------|------|-----------|
| `avatars` | ✅ | صور المستخدمين الشخصية |
| `website-images` | ✅ | صور المواقع والمحتوى |

### إنشاء الحاويات
```sql
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('website-images', 'website-images', true);
```

### سياسات تخزين RLS
```sql
-- Avatars bucket policies
CREATE POLICY "Avatar Images Read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Avatar Images Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars');
CREATE POLICY "Avatar Images Update" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars');
CREATE POLICY "Avatar Images Delete" ON storage.objects FOR DELETE USING (bucket_id = 'avatars');
```

> **ملاحظة:** حاوية `website-images` لا تحتوي على سياسات RLS مخصصة حالياً.

---

## 11. Edge Functions

### ملخص (7 وظائف)

| الوظيفة | الإصدار | JWT | الغرض |
|---------|---------|-----|--------|
| `ai-assistant` | v23 | ❌ | مساعد الذكاء الاصطناعي للمستخدمين (Ollama + Jina) |
| `ai-content-prep` | v10 | ❌ | تحضير المحتوى بالذكاء الاصطناعي (للأدمن) |
| `send-notification` | v24 | ❌ | إرسال إشعار لجميع المشتركين (OneSignal) |
| `self-test-notification` | v1 | ❌ | إرسال إشعار تجريبي لجهاز واحد |
| `admin-user-actions` | v2 | ❌ | عمليات إدارة المستخدمين (إنشاء/حذف/تعديل) |
| `check-pending-referrals` | v2 | ❌ | فحص الإحالات المعلقة وتأكيدها/إنهائها |
| `create-test-user` | v4 | ❌ | إنشاء مستخدم تجريبي للاختبار |

### الكود المصدري
**✅ كود جميع الـ Edge Functions محفوظ محلياً في:**
```
supabase/functions/
├── ai-assistant/index.ts
├── ai-content-prep/index.ts
├── admin-user-actions/index.ts
├── check-pending-referrals/index.ts
├── create-test-user/index.ts
├── send-notification/index.ts
└── self-test-notification/index.ts
```

### أمر النشر (Deploy)
```bash
# نشر جميع الوظائف على المشروع الجديد
supabase functions deploy ai-assistant --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy ai-content-prep --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy send-notification --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy self-test-notification --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy admin-user-actions --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy check-pending-referrals --no-verify-jwt --project-ref <NEW_PROJECT_REF>
supabase functions deploy create-test-user --no-verify-jwt --project-ref <NEW_PROJECT_REF>
```

---

## 12. المتغيرات السرية (Secrets)

| المفتاح | الوصف | مُستخدم في |
|---------|-------|------------|
| `ONESIGNAL_APP_ID` | معرف تطبيق OneSignal | send-notification, self-test-notification |
| `ONESIGNAL_REST_API_KEY` | مفتاح OneSignal REST API | send-notification, self-test-notification |
| `OLLAMA_API_KEY` | مفتاح Ollama Cloud API | ai-assistant, ai-content-prep |
| `LLM_BASE_URL` | رابط Ollama API | ai-assistant, ai-content-prep |
| `SUPABASE_URL` | يُوفَّر تلقائياً | create-test-user, admin-user-actions, check-pending-referrals |
| `SUPABASE_SERVICE_ROLE_KEY` | يُوفَّر تلقائياً | create-test-user, admin-user-actions, check-pending-referrals |

### ضبط المفاتيح
```bash
supabase secrets set ONESIGNAL_APP_ID=<your-app-id> --project-ref <NEW_REF>
supabase secrets set ONESIGNAL_REST_API_KEY=<your-api-key> --project-ref <NEW_REF>
supabase secrets set OLLAMA_API_KEY=<your-ollama-key> --project-ref <NEW_REF>
supabase secrets set LLM_BASE_URL=https://ollama.com/api/chat --project-ref <NEW_REF>
```

---

## 13. إعداد المصادقة (Authentication)

| الإعداد | القيمة |
|---------|--------|
| Auth Provider | Email/Password فقط |
| Email Confirmation | مفعّل |
| Secure Password | مفعّل |

> **يجب التحقق يدوياً من Dashboard:**
> - Auth → Providers: تأكد أن Email/Password مفعّل فقط.
> - Auth → Email Templates: إذا عدّلت قوالب البريد (OTP، Reset Password)، انسخها.
> - Auth → URL Configuration: إعدادات Redirect URLs.

---

## 14. تحديث تطبيق Flutter

### الملفات التي يجب تحديثها عند تغيير المشروع:

#### `lib/core/supabase_config.dart`
```dart
class SupabaseConfig {
  static const String url = '<NEW_SUPABASE_URL>';
  static const String anonKey = '<NEW_ANON_KEY>';
}
```

#### `android/app/google-services.json`
- تأكد أنه يحتوي على بيانات Firebase الصحيحة (إذا كنت تستخدم Firebase مع OneSignal).

#### `ios/Runner/GoogleService-Info.plist`
- نفس الملاحظة لـ iOS.

---

## 15. ما يجب استخراجه يدوياً ⚠️

> **هذه العناصر لا يمكن لأي وكيل برمجي استخراجها تلقائياً:**

### ✏️ يجب عليك حفظها الآن في ملف آمن

| العنصر | الموقع | كيفية الاستخراج |
|--------|--------|-----------------|
| **ONESIGNAL_APP_ID** | Supabase Dashboard → Edge Functions → Secrets | انسخ القيمة |
| **ONESIGNAL_REST_API_KEY** | Supabase Dashboard → Edge Functions → Secrets | انسخ القيمة |
| **OLLAMA_API_KEY** | Supabase Dashboard → Edge Functions → Secrets | انسخ القيمة |
| **قوالب البريد المعدّلة** | Supabase Dashboard → Auth → Email Templates | انسخ HTML إذا عدّلت |
| **OneSignal Firebase Server Key** | OneSignal Dashboard → Settings → Platforms → Android | انسخ المفتاح |
| **Google Console SHA-1/SHA-256** | Google Cloud Console → APIs & Services → Credentials | انسخ المفاتيح |
| **OAuth Client IDs** (إذا وجدت) | Google Cloud Console → OAuth 2.0 Client IDs | انسخ |
| **google-services.json** | تأكد أنه محفوظ في `android/app/` على GitHub | ✅ محفوظ |
| **DNS/Custom Domain** | Supabase Dashboard → Settings → Custom Domains | وثّق إذا وجد |

### 📋 قائمة التحقق اليدوية عند الترحيل

```
□ نسخت قيم ONESIGNAL_APP_ID و ONESIGNAL_REST_API_KEY
□ نسخت قيمة OLLAMA_API_KEY
□ نسخت قوالب البريد المعدّلة (إذا وجدت)
□ حفظت google-services.json و GoogleService-Info.plist
□ وثّقت إعدادات OneSignal Dashboard
□ وثّقت Google Console credentials
□ وثّقت أي Custom Domain
```

---

## 16. خطوات إعادة البناء الكاملة

### المرحلة 1: الإعداد الآلي (يقوم به الوكيل الذكي)

```
1. ✅ أنشئ مشروع Supabase جديد
2. ✅ فعّل الإضافات المطلوبة (القسم 2)
3. ✅ شغّل الـ 38 Migration بالترتيب  ← ينشئ كل الجداول + الدوال + المشغلات + السياسات + الفهارس
4. ✅ أنشئ حاويات التخزين + سياساتها (القسم 10)
5. ✅ فعّل Realtime على الجداول المطلوبة (القسم 8)
6. ✅ أنشئ الـ Cron Jobs (القسم 9)
7. ✅ انشر جميع الـ 7 Edge Functions (القسم 11)
8. ✅ حدّث supabase_config.dart بالـ URL والـ anon key الجديدين
```

### المرحلة 2: الإعداد اليدوي (تقوم به أنت)

```
1. ⚙️ اضبط Secrets في Edge Functions (القسم 12)
2. ⚙️ تحقق من إعدادات Auth (القسم 13)
3. ⚙️ اربط OneSignal بالمشروع الجديد
4. ⚙️ حدّث Google Console (إذا لزم)
5. ⚙️ تأكد من ملفات Firebase (google-services.json)
6. ⚙️ اختبر بالدخول من التطبيق
```

---

## 17. تصدير/استيراد البيانات

> **هذه الوثيقة تغطي الهيكل.** لنقل البيانات الفعلية:

### تصدير البيانات
```bash
# تصدير كل البيانات من المشروع الحالي
pg_dump "postgresql://postgres:<DB_PASSWORD>@db.poepodtageytnzucrsmg.supabase.co:5432/postgres" \
  --data-only --schema=public > data_backup.sql
```

### استيراد البيانات
```bash
# استيراد إلى المشروع الجديد
psql "postgresql://postgres:<NEW_DB_PASSWORD>@db.<NEW_PROJECT_REF>.supabase.co:5432/postgres" \
  < data_backup.sql
```

### كلمة مرور قاعدة البيانات
- Supabase Dashboard → Settings → Database → Database Password
- أو أعد تعيينها من نفس الصفحة.

---

> **آخر تحديث:** 2026-04-12 | **مُولّد ومُتحقق منه** مقابل المشروع الحي `poepodtageytnzucrsmg`
