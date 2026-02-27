# Admin Analytics & Monitoring Dashboard

Build a comprehensive analytics system allowing the admin to monitor users, track activity, see popular items, and make data-driven decisions.

## Current State

- **Admin dashboard:** Basic stats (Total Users, Websites, Categories) + 7 management action cards
- **No activity tracking** — no way to know who's active, what's popular, or usage trends
- **`adminStatsProvider`:** Only counts 3 tables

## Proposed Changes

### 1. Database — New Analytics Tables

#### [NEW] `user_activity` table
Tracks user login/open events to determine active users.

| Column | Type | Purpose |
|---|---|---|
| [id](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_dashboard_screen.dart#261-324) | uuid PK | |
| `user_id` | uuid FK→profiles | Who |
| `activity_type` | text | `app_open`, `login`, `search`, [bookmark](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/discover/discover_screen.dart#1113-1148) |
| `metadata` | jsonb | Extra context (e.g. search query) |
| `created_at` | timestamptz | When |

#### [NEW] `item_views` table
Tracks discover item views/opens for popularity ranking.

| Column | Type | Purpose |
|---|---|---|
| [id](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_dashboard_screen.dart#261-324) | uuid PK | |
| `user_id` | uuid FK→profiles | Who viewed |
| `website_id` | uuid FK→websites | What was viewed |
| `created_at` | timestamptz | When |

---

### 2. Flutter — Track User Activity

#### [MODIFY] [main.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/main.dart)
- Log `app_open` event on app start (insert into `user_activity`)

#### [NEW] [lib/core/services/analytics_service.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/core/services/analytics_service.dart)
Static methods:
- [trackAppOpen()](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/core/services/analytics_service.dart#28-37) — called once per app launch
- [trackItemView(websiteId)](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/core/services/analytics_service.dart#52-67) — called when user opens discover item details
- [trackSearch(query)](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/core/services/analytics_service.dart#38-43) — called on discover search
- [trackBookmark(websiteId)](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/core/services/analytics_service.dart#44-51) — called on bookmark toggle

#### [MODIFY] [website_details_dialog.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/presentation/widgets/website_details_dialog.dart)
- Call `AnalyticsService.trackItemView(site.id)` on dialog open

#### [MODIFY] [discover_screen.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/discover/discover_screen.dart)
- Call `AnalyticsService.trackSearch(query)` on search submit

---

### 4. Admin UI — Dedicated Analytics Screen

#### [MODIFY] [admin_dashboard_screen.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_dashboard_screen.dart)
- Add a new [_ActionCard](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_dashboard_screen.dart#378-465) titled **"App Activities"** (icon: chart, color: Indigo) that navigates to `/admin/analytics`.

#### [NEW] [admin_analytics_screen.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_analytics_screen.dart)
Create a beautiful, dedicated analytics dashboard with 4 distinct sections:

**Section 1: Overview KPIs** (Top row cards)
- 👥 Total Users / Active Today
- 📊 Total Item Views / Bookmarks
- 🔔 Notifications Sent / Pending Suggestions

**Section 2: Activity Chart** (using `fl_chart`)
- Line chart visualizing Daily Active Users (DAU) over the last 30 days.

**Section 3: Popular Content** (Horizontal lists or grids)
- Top 10 most viewed items (with view count)
- Top 10 most bookmarked items

**Section 4: Recent Activity Feed** (Vertical list)
- Latest user signups  
- Latest searches  
- Latest app opens

---

### 4. RLS Policies

- `user_activity`: Users can INSERT their own, admin can SELECT all
- `item_views`: Users can INSERT their own, admin can SELECT all

## Verification Plan

### Automated
- `flutter analyze` → 0 errors
- Test SQL queries via Supabase MCP

### Manual
- Open app → verify `app_open` event logged
- Open discover item → verify `item_view` logged
- Check admin dashboard shows real data
- Verify charts render with `fl_chart`

## Phase 4: Analytics Optimization
### 1. Database Operations (Retention & Aggregation)
#### [NEW] SQL Migration: `optimize_analytics`
- Create RPC `cleanup_old_analytics()` that deletes rows from `user_activity` and `item_views` where `created_at < NOW() - INTERVAL '15 days'`.
- Schedule the RPC using `pg_cron` (if supported by the DB instance) or prepare it to be called from edge functions.
- Create RPC `get_top_searches(days INT)` that groups `metadata->>'query'` from `user_activity` (where `activity_type = 'search'`), counts occurrences, and returns the top 10 results.

### 2. Flutter Changes
#### [MODIFY] [lib/presentation/providers/admin_analytics_provider.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/presentation/providers/admin_analytics_provider.dart)
- Remove the queries for Recent Signups, Recent Searches, and Recent App Opens (the old "Feed").
- Update the parameters of existing RPC calls to be 15 days instead of 30.
- Call the new `get_top_searches(15)` to fetch the trending search queries.
#### [MODIFY] [lib/features/admin/admin_analytics_screen.dart](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_analytics_screen.dart)
- Remove [_FeedHeader](file:///c:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_analytics_screen.dart#679-705) and [_FeedItem](file:///C:/Users/Administrator/Downloads/flutter_app/WebVault/lib/features/admin/admin_analytics_screen.dart#706-790) classes entirely.
- In the main layout, swap the "Recent Activity Feed" with a new "Top Researched Items (15 Days)" section using a horizontal list or grid.
- Adjust chart and section titles to clearly indicate data is for "15 Days".
