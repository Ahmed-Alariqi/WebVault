import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../data/models/referral_model.dart';
import '../../data/models/membership_request_model.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../presentation/providers/membership_providers.dart';
import '../../presentation/providers/auth_providers.dart';

final adminPersonasProvider = FutureProvider<List<dynamic>>((ref) async {
  final resp = await SupabaseConfig.client
      .from('ai_personas')
      .select('id, name, icon, is_premium')
      .eq('is_premium', true)
      .order('sort_order');
  return resp as List;
});

final adminCollectionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final resp = await SupabaseConfig.client
      .from('featured_collections')
      .select('id, title, is_referral_exclusive')
      .eq('is_referral_exclusive', true)
      .order('sort_order');
  return resp as List;
});

Future<void> togglePersonaPremium(String id, bool isPremium, WidgetRef ref) async {
  try {
    await SupabaseConfig.client.from('ai_personas').update({'is_premium': isPremium}).eq('id', id);
    ref.invalidate(adminPersonasProvider);
  } catch (e) {
    debugPrint('togglePersonaPremium error: $e');
  }
}

Future<void> toggleCollectionPremium(String id, bool isPremium, WidgetRef ref) async {
  try {
    await SupabaseConfig.client.from('featured_collections').update({'is_referral_exclusive': isPremium}).eq('id', id);
    ref.invalidate(adminCollectionsProvider);
  } catch (e) {
    debugPrint('toggleCollectionPremium error: $e');
  }
}

Future<void> updateAppSetting(String key, String value, WidgetRef ref) async {
  try {
    await SupabaseConfig.client.from('app_settings').update({'value': value}).eq('key', key);
    ref.invalidate(appSettingsProvider);
  } catch (e) {
    debugPrint('updateAppSetting error: $e');
  }
}

Future<void> approveMembershipRequest({
  required String requestId,
  required String userId,
  required Duration duration,
  required MembershipScope scope,
  required WidgetRef ref,
  List<String>? targetIds,
}) async {
  try {
    final supabase = SupabaseConfig.client;

    // 1. Grant actual membership logic via provider
    // This is the most critical step - we do it FIRST so if it fails,
    // the request status remains 'pending' and we don't give false feedback.
    await ref.read(membershipManagementProvider).grantMembership(
          userId: userId,
          duration: duration,
          scope: scope,
          targetIds: targetIds,
        );

    // 2. Update request status only after successful grant
    await supabase.from('membership_requests').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': supabase.auth.currentUser?.id,
    }).eq('id', requestId);

    ref.invalidate(adminMembershipRequestsProvider);
    ref.invalidate(userProfileProvider);
  } catch (e) {
    debugPrint('Error approving: $e');
    rethrow;
  }
}

class AdminMembershipScreen extends ConsumerStatefulWidget {
  const AdminMembershipScreen({super.key});
  @override
  ConsumerState<AdminMembershipScreen> createState() => _AdminMembershipScreenState();
}

class _AdminMembershipScreenState extends ConsumerState<AdminMembershipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), AppTheme.primaryColor],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, top: -10,
                      child: Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                          size: 150, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('MEMBERSHIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 8),
                          const Text('إدارة العضوية', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          Text('إدارة الإعدادات والطلبات والدعوات', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              Container(
                color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    padding: const EdgeInsets.all(4),
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.gear(), size: 16), const SizedBox(width: 4), const Text('الإعدادات')])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.envelopeSimple(), size: 16), const SizedBox(width: 4), const Text('الطلبات')])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.usersThree(), size: 16), const SizedBox(width: 4), const Text('الدعوات')])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.identificationCard(), size: 16), const SizedBox(width: 4), const Text('الأعضاء')])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _SettingsTab(isDark: isDark),
            _RequestsTab(isDark: isDark),
            _ReferralsTab(isDark: isDark),
            _MembersTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 1: SETTINGS
// ══════════════════════════════════════════

class _SettingsTab extends ConsumerWidget {
  final bool isDark;
  const _SettingsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final personasAsync = ref.watch(adminPersonasProvider);

    return settingsAsync.when(
      data: (settings) {
        final reqInvites = int.tryParse(settings['default_required_invites'] ?? '3') ?? 3;
        final reqEnabled = settings['membership_requests_enabled'] == 'true';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Required Invites
            _SettingCard(
              icon: PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
              color: AppTheme.primaryColor,
              title: 'عدد الدعوات المطلوبة',
              subtitle: 'العدد الافتراضي لفتح المحتوى المميز',
              isDark: isDark,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: reqInvites > 1 ? () => updateAppSetting('default_required_invites', '${reqInvites - 1}', ref) : null,
                    icon: Icon(PhosphorIcons.minus(), size: 18, color: isDark ? Colors.white54 : Colors.black45),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Container(
                    width: 44, height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('$reqInvites', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87))),
                  ),
                  IconButton(
                    onPressed: () => updateAppSetting('default_required_invites', '${reqInvites + 1}', ref),
                    icon: Icon(PhosphorIcons.plus(), size: 18, color: isDark ? Colors.white54 : Colors.black45),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
            const SizedBox(height: 12),

            // Membership Requests Toggle
            _SettingCard(
              icon: PhosphorIcons.envelopeOpen(PhosphorIconsStyle.fill),
              color: const Color(0xFF10B981),
              title: 'طلبات العضوية',
              subtitle: 'السماح بإرسال طلبات يدوية',
              isDark: isDark,
              trailing: Switch.adaptive(
                value: reqEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => updateAppSetting('membership_requests_enabled', v ? 'true' : 'false', ref),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),

            // Personas Premium Management
            Row(
              children: [
                Icon(PhosphorIcons.robot(PhosphorIconsStyle.bold), size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('شخصيات خبير زاد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Text('حدد الشخصيات التي تتطلب عضوية للوصول إليها', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 12),
            personasAsync.when(
              data: (personas) => Column(
                children: personas.asMap().entries.map((e) {
                  final p = e.value;
                  final isPrem = p['is_premium'] as bool? ?? false;
                  return _SettingCard(
                    icon: PhosphorIcons.robot(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                    title: p['name'] as String,
                    subtitle: isPrem ? '✦ مميزة (Premium)' : 'مجانية للجميع',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isPrem,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) async {
                        await togglePersonaPremium(p['id'] as String, v, ref);
                        ref.invalidate(adminPersonasProvider);
                      },
                    ),
                  ).animate().fadeIn(delay: (e.key * 50).ms).slideX(begin: 0.05);
                }).toList(),
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red)))),
            ),
            
            const SizedBox(height: 32),
            
            // Collections Premium Management
            Row(
              children: [
                Icon(PhosphorIcons.stack(PhosphorIconsStyle.bold), size: 20, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Text('المجموعات المميزة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Text('حدد المجموعات التي تتطلب عضوية أو دعوات', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 12),
            ref.watch(adminCollectionsProvider).when(
              data: (collections) => Column(
                children: collections.asMap().entries.map((e) {
                  final c = e.value;
                  final isPrem = c['is_referral_exclusive'] as bool? ?? false;
                  return _SettingCard(
                    icon: PhosphorIcons.folderStar(PhosphorIconsStyle.fill),
                    color: const Color(0xFFF59E0B),
                    title: c['title'] as String,
                    subtitle: isPrem ? '✦ مميزة (Premium)' : 'عامة للجميع',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isPrem,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) async {
                        await toggleCollectionPremium(c['id'] as String, v, ref);
                        ref.invalidate(adminCollectionsProvider);
                      },
                    ),
                  ).animate().fadeIn(delay: (e.key * 50).ms).slideX(begin: 0.05);
                }).toList(),
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red)))),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 2: MEMBERSHIP REQUESTS
// ══════════════════════════════════════════

class _RequestsTab extends ConsumerWidget {
  final bool isDark;
  const _RequestsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminMembershipRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.tray(PhosphorIconsStyle.duotone), size: 64, color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 12),
                Text('لا توجد طلبات عضوية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminMembershipRequestsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (ctx, i) => _RequestCard(request: requests[i], isDark: isDark)
                .animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.05),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final MembershipRequest request;
  final bool isDark;
  const _RequestCard({required this.request, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = request.isPending ? Colors.amber : request.isApproved ? AppTheme.successColor : AppTheme.errorColor;
    final statusLabel = request.isPending ? 'قيد المراجعة' : request.isApproved ? 'مقبول' : 'مرفوض';
    final statusIcon = request.isPending
        ? PhosphorIcons.clock(PhosphorIconsStyle.fill)
        : request.isApproved
            ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
            : PhosphorIcons.xCircle(PhosphorIconsStyle.fill);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: request.isPending ? statusColor.withValues(alpha: 0.3) : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.userName ?? request.userUsername ?? 'مستخدم', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                    if (request.userEmail != null) Text(request.userEmail!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
              child: Text(request.reason!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.4)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(PhosphorIcons.calendar(), size: 14, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Text(DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt), style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
              const Spacer(),
              if (request.isPending) ...[
                _ActionBtn(
                  icon: PhosphorIcons.check(), color: AppTheme.successColor, label: 'قبول',
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) => _MembershipGrantDialog(userName: request.userName ?? 'المستخدم'),
                    );

                    if (result != null) {
                      await approveMembershipRequest(
                        requestId: request.id,
                        userId: request.userId,
                        duration: result['duration'] as Duration,
                        scope: result['scope'] as MembershipScope,
                        targetIds: result['targetIds'] as List<String>?,
                        ref: ref,
                      );
                      if (context.mounted) AdminUIUtils.showSuccess(context, 'تم تفعيل العضوية للمستخدم بنجاح');
                    }
                  },
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: PhosphorIcons.x(), color: AppTheme.errorColor, label: 'رفض',
                  onTap: () async {
                    await rejectMembershipRequest(request.id, ref);
                    if (context.mounted) AdminUIUtils.showSuccess(context, 'تم رفض الطلب');
                  },
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (request.status == 'rejected')
                      IconButton(
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (ctx) => _MembershipGrantDialog(userName: request.userName ?? 'المستخدم'),
                          );

                          if (result != null) {
                            await approveMembershipRequest(
                              requestId: request.id,
                              userId: request.userId,
                              duration: result['duration'] as Duration,
                              scope: result['scope'] as MembershipScope,
                              targetIds: result['targetIds'] as List<String>?,
                              ref: ref,
                            );
                            if (context.mounted) AdminUIUtils.showSuccess(context, 'تم تفعيل العضوية للمستخدم بنجاح');
                          }
                        },
                        icon: Icon(PhosphorIcons.checkCircle(), size: 20, color: AppTheme.successColor.withValues(alpha: 0.7)),
                        tooltip: 'قبول الآن',
                      ),
                    IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('حذف السجل؟'),
                            content: const Text('سيتم حذف هذا الطلب من السجل. سيتمكن المستخدم من إرسال طلب جديد.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await deleteMembershipRequest(request.id, ref);
                          if (context.mounted) AdminUIUtils.showSuccess(context, 'تم حذف السجل بنجاح');
                        }
                      },
                      icon: Icon(PhosphorIcons.trash(), size: 18, color: isDark ? Colors.white24 : Colors.black26),
                      tooltip: 'حذف السجل',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 3: ALL REFERRALS
// ══════════════════════════════════════════

class _ReferralsTab extends ConsumerWidget {
  final bool isDark;
  const _ReferralsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(allReferralsProvider);

    return referralsAsync.when(
      data: (referrals) {
        if (referrals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.duotone), size: 64, color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 16),
                Text('لا توجد دعوات حالياً', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          );
        }

        final confirmed = referrals.where((r) => r.isConfirmed).length;
        final pending = referrals.where((r) => r.isPending).length;
        final expired = referrals.where((r) => r.isExpired).length;

        // Group by referrer
        final Map<String, List<Referral>> grouped = {};
        for (final r in referrals) {
          grouped.putIfAbsent(r.referrerId, () => []).add(r);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allReferralsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Stats Row
              Row(
                children: [
                  _StatPill(label: 'الكل', count: referrals.length, color: AppTheme.primaryColor, isDark: isDark),
                  const SizedBox(width: 8),
                  _StatPill(label: 'مؤكدة', count: confirmed, color: AppTheme.successColor, isDark: isDark),
                  const SizedBox(width: 8),
                  _StatPill(label: 'معلقة', count: pending, color: Colors.amber, isDark: isDark),
                  const SizedBox(width: 8),
                  _StatPill(label: 'منتهية', count: expired, color: Colors.grey, isDark: isDark),
                ],
              ).animate().fadeIn(),
              const SizedBox(height: 20),

              // Grouped Referrers
              ...grouped.entries.map((entry) {
                final referrerRefs = entry.value;
                final referrerName = referrerRefs.first.referrerUsername ?? referrerRefs.first.referrerName ?? '?';
                final confirmedCount = referrerRefs.where((r) => r.isConfirmed).length;
                final pendingCount = referrerRefs.where((r) => r.isPending).length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text('${referrerRefs.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor))),
                      ),
                      title: Text('@$referrerName', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Row(
                        children: [
                          if (confirmedCount > 0) _MiniStatChip(count: confirmedCount, color: AppTheme.successColor, icon: PhosphorIcons.check()),
                          if (pendingCount > 0) _MiniStatChip(count: pendingCount, color: Colors.amber, icon: PhosphorIcons.clock()),
                        ],
                      ),
                      children: referrerRefs.map((r) => _ReferralCard(referral: r, isDark: isDark)).toList(),
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: 0.05);
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _ReferralCard extends ConsumerWidget {
  final Referral referral;
  final bool isDark;
  const _ReferralCard({required this.referral, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = referral.isConfirmed ? AppTheme.successColor : referral.isPending ? Colors.amber : referral.isExpired ? Colors.grey : AppTheme.errorColor;
    final statusIcon = referral.isConfirmed ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : referral.isRejected ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill) : referral.isExpired ? PhosphorIcons.clockCountdown(PhosphorIconsStyle.fill) : PhosphorIcons.clock(PhosphorIconsStyle.fill);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${referral.referredUsername ?? '?'}', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                    Text(DateFormat('yyyy/MM/dd HH:mm').format(referral.createdAt), style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                  ],
                ),
              ),
              // Actions
              if (referral.isPending || referral.isExpired) ...[
                IconButton(
                  onPressed: () async {
                    await approveReferral(referral.id, ref);
                    if (context.mounted) AdminUIUtils.showSuccess(context, 'تم تأكيد الإحالة');
                  },
                  icon: Icon(PhosphorIcons.check(), color: AppTheme.successColor, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  onPressed: () async {
                    await rejectReferral(referral.id, ref);
                    if (context.mounted) AdminUIUtils.showSuccess(context, 'تم رفض الإحالة');
                  },
                  icon: Icon(PhosphorIcons.x(), color: AppTheme.errorColor, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
          // Activity Indicator for Anti-Fraud
          if (referral.isPending || referral.isExpired || referral.isConfirmed)
            _ReferralActivityIndicator(
              referredId: referral.referredId,
              referralCreatedAt: referral.createdAt,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;
  final Widget trailing;
  const _SettingCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.isDark, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;
  const _StatPill({required this.label, required this.count, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;
  const _MiniStatChip({required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ReferralActivityIndicator extends StatefulWidget {
  final String referredId;
  final DateTime referralCreatedAt;
  final bool isDark;
  const _ReferralActivityIndicator({required this.referredId, required this.referralCreatedAt, required this.isDark});

  @override
  State<_ReferralActivityIndicator> createState() => _ReferralActivityIndicatorState();
}

class _ReferralActivityIndicatorState extends State<_ReferralActivityIndicator> {
  Map<String, dynamic>? _activityData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final supabase = SupabaseConfig.client;
      // 1. Profile check
      final profile = await supabase.from('profiles').select('full_name, username').eq('id', widget.referredId).single();
      final hasProfile = (profile['full_name'] as String?)?.isNotEmpty == true && (profile['username'] as String?)?.isNotEmpty == true;

      // 2. App opens
      final appOpens = await supabase.from('user_activity').select('id').eq('user_id', widget.referredId).eq('activity_type', 'app_open').gte('created_at', widget.referralCreatedAt.toIso8601String());
      final loginCount = (appOpens as List).length;

      // 3. Content activity
      final contentActs = await supabase.from('user_activity').select('id').eq('user_id', widget.referredId).inFilter('activity_type', ['item_view', 'clipboard_add', 'page_add', 'search', 'bookmark']).gte('created_at', widget.referralCreatedAt.toIso8601String()).limit(1);
      final hasContent = (contentActs as List).isNotEmpty;

      if (mounted) {
        setState(() {
          _activityData = {'hasProfile': hasProfile, 'loginCount': loginCount, 'hasContent': hasContent};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.only(top: 8), child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5)));
    if (_activityData == null) return const SizedBox();

    final hasProfile = _activityData!['hasProfile'] as bool;
    final loginCount = _activityData!['loginCount'] as int;
    final hasContent = _activityData!['hasContent'] as bool;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _ActivityDot(label: 'بروفايل', done: hasProfile, isDark: widget.isDark),
          const SizedBox(width: 8),
          _ActivityDot(label: 'دخول $loginCount/3', done: loginCount >= 3, isDark: widget.isDark),
          const SizedBox(width: 8),
          _ActivityDot(label: 'نشاط', done: hasContent, isDark: widget.isDark),
        ],
      ),
    );
  }
}

class _ActivityDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool isDark;
  const _ActivityDot({required this.label, required this.done, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppTheme.successColor : (isDark ? Colors.white24 : Colors.black12);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: done ? color : (isDark ? Colors.white38 : Colors.black38), fontWeight: done ? FontWeight.w700 : FontWeight.normal)),
      ],
    );
  }
}

class _MembershipGrantDialog extends StatefulWidget {
  final String userName;
  const _MembershipGrantDialog({required this.userName});

  @override
  State<_MembershipGrantDialog> createState() => _MembershipGrantDialogState();
}

class _MembershipGrantDialogState extends State<_MembershipGrantDialog> {
  Duration _selectedDuration = const Duration(days: 7);
  MembershipScope _selectedScope = MembershipScope.global;
  final List<String> _selectedIds = [];

  final List<Map<String, dynamic>> _durations = [
    {'label': '3 أيام (تجريبي)', 'value': const Duration(days: 3)},
    {'label': 'أسبوع واحد', 'value': const Duration(days: 7)},
    {'label': 'شهر كامل', 'value': const Duration(days: 30)},
    {'label': 'دائم (عضوية مفتوحة)', 'value': const Duration(days: 36500)},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(builder: (context, ref, _) {
      final personas = ref.watch(adminPersonasProvider);
      final collections = ref.watch(adminCollectionsProvider);

      return AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('تحديد تفاصيل العضوية لـ ${widget.userName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مدة العضوية:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              ..._durations.map((d) => RadioListTile<Duration>(
                    value: d['value'] as Duration,
                    groupValue: _selectedDuration,
                    title: Text(d['label'] as String, style: const TextStyle(fontSize: 14)),
                    onChanged: (val) => setState(() => _selectedDuration = val!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
              const Divider(height: 32),
              const Text('نطاق الوصول:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              DropdownButtonFormField<MembershipScope>(
                value: _selectedScope,
                decoration: _adminInputDecoration(isDark, label: 'اختر النطاق').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: MembershipScope.global, child: Text('وصول كامل لكل الميزات')),
                  DropdownMenuItem(value: MembershipScope.collection, child: Text('مجموعات محددة فقط')),
                  DropdownMenuItem(value: MembershipScope.persona, child: Text('شخصيات خبير زاد محددة')),
                ],
                onChanged: (val) => setState(() {
                  _selectedScope = val!;
                  _selectedIds.clear();
                }),
              ),
              if (_selectedScope != MembershipScope.global) ...[
                const SizedBox(height: 20),
                const Text('اختر العناصر المحددة:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                if (_selectedScope == MembershipScope.persona)
                  personas.maybeWhen(
                    data: (items) => Wrap(
                      spacing: 8,
                      children: items.map((p) {
                        final id = p['id'] as String;
                        final isSelected = _selectedIds.contains(id);
                        return FilterChip(
                          label: Text(p['name'] as String, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => val ? _selectedIds.add(id) : _selectedIds.remove(id)),
                        );
                      }).toList(),
                    ),
                    orElse: () => const Center(child: CircularProgressIndicator()),
                  )
                else
                  collections.maybeWhen(
                    data: (items) => Wrap(
                      spacing: 8,
                      children: items.map((c) {
                        final id = c['id'] as String;
                        final isSelected = _selectedIds.contains(id);
                        return FilterChip(
                          label: Text(c['title'] as String, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => val ? _selectedIds.add(id) : _selectedIds.remove(id)),
                        );
                      }).toList(),
                    ),
                    orElse: () => const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'duration': _selectedDuration,
              'scope': _selectedScope,
              'targetIds': _selectedIds.isEmpty ? null : _selectedIds,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تأكيد ومنح الوصول'),
          ),
        ],
      );
    });
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabBarDelegate(this.child);
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) => child;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}

InputDecoration _adminInputDecoration(bool isDark, {required String label}) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
class _MembersTab extends ConsumerWidget {
  final bool isDark;
  const _MembersTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(activePremiumUsersProvider);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.users(PhosphorIconsStyle.duotone), size: 64, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 12),
                Text('لا يوجد أعضاء مفعّلون حالياً', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activePremiumUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: members.length,
            itemBuilder: (context, i) {
              final m = members[i];
              final premiumUntil = m['premium_until'] != null ? DateTime.parse(m['premium_until']) : null;
              final isExpired = premiumUntil != null && premiumUntil.isBefore(DateTime.now());
              final isPermanent = premiumUntil != null && premiumUntil.year > 2099;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.person, color: AppTheme.primaryColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['full_name'] ?? m['username'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(isPermanent ? 'عضوية دائمة ♾️' : 'تنتهي: ${DateFormat('yyyy/MM/dd').format(premiumUntil!)}', 
                              style: TextStyle(fontSize: 12, color: isExpired ? AppTheme.errorColor : (isDark ? Colors.white38 : Colors.black38))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.dotsThreeOutlineVertical(PhosphorIconsStyle.fill), size: 20),
                      onPressed: () => _showMemberActions(context, ref, m, isDark),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  void _showMemberActions(BuildContext context, WidgetRef ref, Map<String, dynamic> member, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('إدارة عضوية ${member['full_name'] ?? member['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('إعادة ضبط لشهر واحد (30 يوم)'),
              subtitle: const Text('سيتم تقليص المدة لتنتهي بعد شهر من الآن'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(membershipManagementProvider).updateMembership(
                  userId: member['id'],
                  premiumUntil: DateTime.now().add(const Duration(days: 30)),
                );
                ref.invalidate(activePremiumUsersProvider);
                if (context.mounted) AdminUIUtils.showSuccess(context, 'تم إعادة ضبط العضوية');
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: Colors.blue),
              title: const Text('ترقية لعضوية دائمة'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(membershipManagementProvider).updateMembership(
                  userId: member['id'],
                  premiumUntil: DateTime(2100, 1, 1),
                );
                ref.invalidate(activePremiumUsersProvider);
                if (context.mounted) AdminUIUtils.showSuccess(context, 'تمت الترقية لعضوية دائمة');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.no_accounts, color: AppTheme.errorColor),
              title: const Text('إلغاء العضوية فوراً', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(membershipManagementProvider).updateMembership(
                  userId: member['id'],
                  premiumUntil: null,
                  permissions: [], // Clear permissions too
                );
                ref.invalidate(activePremiumUsersProvider);
                if (context.mounted) AdminUIUtils.showWarning(context, 'تم إلغاء العضوية');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
