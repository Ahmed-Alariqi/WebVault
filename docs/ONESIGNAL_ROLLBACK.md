# OneSignal Rollback Documentation

> **Created:** 2026-04-13
> **Purpose:** If the notification block is NOT from OneSignal and you need to revert back, follow these steps.

## What Was Changed

### 1. pubspec.yaml
**Removed:**
```yaml
# Push Notifications
onesignal_flutter: ^5.2.12
```
**Added instead:**
```yaml
# Push Notifications (FCM Direct)
firebase_core: ^3.13.0
firebase_messaging: ^15.2.4
```
**Rollback:** Reverse the above (remove firebase packages, add back onesignal_flutter).

---

### 2. lib/core/supabase_config.dart
**Removed:**
```dart
static const String oneSignalAppId =
    '488da896-9e12-4b54-ac4c-b766a9358d55';
```
**Rollback:** Add the constant back.

---

### 3. lib/main.dart
**Removed:** All OneSignal SDK code (initialization, push subscription observer, auth state listener for OneSignal login/logout, foreground display listener, click listener).

**Original OneSignal code that was in main():**
```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

// Initialize OneSignal
OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
OneSignal.initialize(SupabaseConfig.oneSignalAppId);

// Request push notification permission
OneSignal.Notifications.requestPermission(true);

// Enable push subscription explicitly (OneSignal v5+ requires this)
OneSignal.User.pushSubscription.optIn();

// Monitor push subscription changes
OneSignal.User.pushSubscription.addObserver((state) {
  debugPrint('[OneSignal] Push subscription changed:');
  debugPrint('[OneSignal]   ID: ${state.current.id}');
  debugPrint('[OneSignal]   Token: ${state.current.token}');
  debugPrint('[OneSignal]   OptedIn: ${state.current.optedIn}');

  final subId = state.current.id;
  final user = SupabaseConfig.client.auth.currentUser;
  if (subId != null && subId.isNotEmpty && user != null) {
    authService
        .updateProfile(onesignalPlayerId: subId)
        .then((_) {
          debugPrint('[OneSignal] Stored subscription ID to profile: $subId');
        })
        .catchError((e) {
          debugPrint('[OneSignal] Failed to store sub ID: $e');
        });
  }
});

// Link Supabase user to OneSignal on auth state changes
SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
  final event = data.event;
  final session = data.session;

  if (event == AuthChangeEvent.signedIn ||
      event == AuthChangeEvent.tokenRefreshed ||
      event == AuthChangeEvent.initialSession) {
    final userId = session?.user.id;
    if (userId != null) {
      await OneSignal.login(userId);
      debugPrint('[OneSignal] Logged in user: $userId');
      OneSignal.User.pushSubscription.optIn();
      final meta = session?.user.userMetadata;
      final userName =
          meta?['username'] as String? ??
          meta?['full_name'] as String? ??
          meta?['name'] as String? ??
          session?.user.email ??
          'there';
      OneSignal.User.addTagWithKey('user_name', userName);
      debugPrint('[OneSignal] Tagged user_name=$userName');
      final subId = OneSignal.User.pushSubscription.id;
      final token = OneSignal.User.pushSubscription.token;
      debugPrint('[OneSignal] Current sub ID: $subId, token: $token');
      if (subId != null && subId.isNotEmpty) {
        try {
          await authService.updateProfile(onesignalPlayerId: subId);
          debugPrint('[OneSignal] Stored subscription ID: $subId');
        } catch (e) {
          debugPrint('[OneSignal] Failed to store sub ID: $e');
        }
      }
    }
  } else if (event == AuthChangeEvent.signedOut) {
    OneSignal.logout();
    debugPrint('[OneSignal] Logged out');
  }
});

// Show notification in foreground AND refresh badge count
OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  debugPrint(
    '[OneSignal] Foreground notification received: ${event.notification.title}',
  );
  event.notification.display();
  container.invalidate(notificationCountProvider);
});

// Also refresh count when notification is clicked
OneSignal.Notifications.addClickListener((event) {
  debugPrint('[OneSignal] Notification clicked: ${event.notification.title}');
  container.invalidate(notificationCountProvider);
  final router = container.read(routerProvider);
  router.go('/notifications');
});
```

---

### 4. lib/data/services/auth_service.dart
**Changed:** Parameter `onesignalPlayerId` → `fcmToken`, DB field `onesignal_player_id` → `fcm_token`

**Original:**
```dart
Future<void> updateProfile({
  String? fullName,
  String? username,
  String? avatarUrl,
  String? onesignalPlayerId,
  bool updateUsernameTimestamp = false,
}) async {
  // ...
  if (onesignalPlayerId != null) {
    updates['onesignal_player_id'] = onesignalPlayerId;
  }
}
```

---

### 5. lib/features/settings/settings_screen.dart
**Changed:** OneSignal subscription check → FCM token check

**Original check:**
```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';
// ...
playerId = OneSignal.User.pushSubscription.id;
isRegistered = playerId != null && playerId.isNotEmpty;
```

---

### 6. Supabase Edge Functions

#### send-notification/index.ts
**Original:** Used OneSignal REST API at `https://onesignal.com/api/v1/notifications`
with `ONESIGNAL_APP_ID` and `ONESIGNAL_REST_API_KEY` secrets.

#### self-test-notification/index.ts
**Original:** Same OneSignal REST API targeting specific `player_id`.

---

### 7. Supabase Secrets
**Original secrets (DO NOT DELETE, just disable):**
- `ONESIGNAL_APP_ID` = `488da896-9e12-4b54-ac4c-b766a9358d55`
- `ONESIGNAL_REST_API_KEY` = (check Supabase dashboard)

**New secret added:**
- `FCM_SERVICE_ACCOUNT_KEY` = (Firebase service account JSON)

---

### 8. Database
**Added column:** `profiles.fcm_token` (TEXT, NULLABLE)
**NOT deleted:** `profiles.onesignal_player_id` (kept for rollback)

**To rollback database:** No action needed - `onesignal_player_id` column still exists with all data.

---

## Full Rollback Steps

1. Revert `pubspec.yaml`: remove `firebase_core`/`firebase_messaging`, add `onesignal_flutter: ^5.2.12`
2. Revert `lib/main.dart` to use OneSignal code (copy from above)
3. Add back `oneSignalAppId` to `supabase_config.dart`
4. Revert `auth_service.dart` parameter names
5. Revert `settings_screen.dart` to check OneSignal
6. Redeploy original Edge Functions (copy from above or git history)
7. Run `flutter pub get`
8. Build and test
