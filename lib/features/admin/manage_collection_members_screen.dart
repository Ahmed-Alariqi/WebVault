import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../data/models/collection_model.dart';
import '../../presentation/providers/admin_providers.dart';

/// Admin screen to manage which users have access to a premium (referral-exclusive)
/// collection. Lists both manually-granted users and users who qualified via
/// referral campaigns. Only manual entries can be removed; referral-eligible
/// users are read-only (their access is computed from confirmed referrals).
class ManageCollectionMembersScreen extends ConsumerWidget {
  final CollectionModel collection;
  const ManageCollectionMembersScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(collectionMembersProvider(collection.id));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أعضاء المجموعة', style: TextStyle(fontSize: 16)),
            Text(
              collection.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMemberSheet(context, ref),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          'إضافة عضو',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (members) {
          if (members.isEmpty) {
            return _buildEmpty(isDark);
          }
          final manualCount = members.where((m) => m.isManual).length;
          final referralCount =
              members.where((m) => m.isReferralEligible && !m.isManual).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _buildSummary(isDark, manualCount, referralCount),
              const SizedBox(height: 16),
              ...members.map((m) => _buildMemberTile(context, ref, m, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(bool isDark, int manualCount, int referralCount) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            isDark,
            icon: PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
            label: 'مضافون يدوياً',
            value: manualCount,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            isDark,
            icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
            label: 'عبر الإحالات',
            value: referralCount,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.usersThree(),
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد أعضاء بعد',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أضف مستخدمين يدوياً لمنحهم الوصول',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    CollectionMember m,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundImage: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(m.avatarUrl!)
              : null,
          child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
              ? Text(
                  m.displayName.isNotEmpty
                      ? m.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          m.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.email != null && m.email!.isNotEmpty)
              Text(
                m.email!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (m.isManual)
                  _badge(
                    icon: PhosphorIcons.userPlus(),
                    label: 'يدوي',
                    color: AppTheme.primaryColor,
                  ),
                if (m.isReferralEligible)
                  _badge(
                    icon: PhosphorIcons.users(),
                    label: m.viaCampaignTitle ?? 'إحالات',
                    color: Colors.amber,
                  ),
              ],
            ),
          ],
        ),
        trailing: m.isManual
            ? IconButton(
                tooltip: 'إزالة',
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent),
                onPressed: () => _confirmRemove(context, ref, m),
              )
            : Icon(
                PhosphorIcons.lock(),
                size: 18,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    CollectionMember m,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة العضو'),
        content: Text(
          'هل تريد إزالة ${m.displayName} من هذه المجموعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إزالة',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await adminRemoveCollectionMember(collection.id, m.userId);
      ref.invalidate(collectionMembersProvider(collection.id));
      if (context.mounted) {
        AdminUIUtils.showSuccess(context, 'تمت الإزالة');
      }
    } catch (e) {
      if (context.mounted) {
        AdminUIUtils.showError(context, 'فشل: $e');
      }
    }
  }

  void _openAddMemberSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(collection: collection),
    );
  }
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  final CollectionModel collection;
  const _AddMemberSheet({required this.collection});

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  static const int _pageSize = 10;
  String _query = '';
  int _visibleCount = _pageSize;
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usersAsync = ref.watch(adminUsersProvider);
    final membersAsync = ref.watch(collectionMembersProvider(widget.collection.id));
    final existingIds = membersAsync.valueOrNull
            ?.where((m) => m.isManual)
            .map((m) => m.userId)
            .toSet() ??
        const <String>{};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'إضافة عضو',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() {
                  _query = v.trim().toLowerCase();
                  _visibleCount = _pageSize; // reset paging on new query
                }),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو البريد...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
                data: (users) {
                  final filtered = users.where((u) {
                    if (_query.isEmpty) return true;
                    final name =
                        (u['full_name'] as String? ?? '').toLowerCase();
                    final email = (u['email'] as String? ?? '').toLowerCase();
                    final username =
                        (u['username'] as String? ?? '').toLowerCase();
                    return name.contains(_query) ||
                        email.contains(_query) ||
                        username.contains(_query);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('لا توجد نتائج'));
                  }
                  final visible = filtered.take(_visibleCount).toList();
                  final hasMore = _visibleCount < filtered.length;
                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: visible.length + 1, // +1 for footer
                    itemBuilder: (_, i) {
                      if (i == visible.length) {
                        // Footer: "Load more" button or "end" caption
                        if (hasMore) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(
                                    () => _visibleCount += _pageSize),
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: Text(
                                  'عرض المزيد (${filtered.length - _visibleCount})',
                                ),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              '${filtered.length} مستخدم',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          ),
                        );
                      }
                      final u = visible[i];
                      final uid = u['id'] as String;
                      final name = (u['full_name'] as String?)?.trim().isNotEmpty == true
                          ? u['full_name'] as String
                          : (u['username'] as String? ?? 'Unknown');
                      final email = u['email'] as String? ?? '';
                      final avatar = u['avatar_url'] as String?;
                      final already = existingIds.contains(uid);
                      final loading = _busy.contains(uid);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          backgroundImage:
                              (avatar != null && avatar.isNotEmpty)
                                  ? CachedNetworkImageProvider(avatar)
                                  : null,
                          child: (avatar == null || avatar.isEmpty)
                              ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: email.isNotEmpty
                            ? Text(email,
                                style: const TextStyle(fontSize: 11))
                            : null,
                        trailing: already
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: AppTheme.primaryColor),
                                    onPressed: () => _add(uid, name),
                                  ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(String userId, String displayName) async {
    setState(() => _busy.add(userId));
    try {
      final added = await adminAddCollectionMember(widget.collection.id, userId);
      if (!added) {
        if (mounted) AdminUIUtils.showInfo(context, 'العضو موجود مسبقاً');
        return;
      }
      ref.invalidate(collectionMembersProvider(widget.collection.id));

      // Send notification (fire-and-forget UI feedback)
      final pushed = await notifyUser(
        userId: userId,
        title: 'تم فتح مجموعة جديدة لك',
        body: 'أضافك المشرف إلى: ${widget.collection.title}',
        type: 'collection_grant',
        targetUrl: '/collections/${widget.collection.id}',
      );

      if (mounted) {
        AdminUIUtils.showSuccess(
          context,
          pushed
              ? 'تمت الإضافة وإشعار $displayName'
              : 'تمت الإضافة (تعذر إرسال الإشعار)',
        );
      }
    } catch (e) {
      if (mounted) AdminUIUtils.showError(context, 'فشل: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(userId));
    }
  }
}
