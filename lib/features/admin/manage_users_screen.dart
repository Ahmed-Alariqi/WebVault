import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../presentation/widgets/offline_warning_widget.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(adminUsersPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => _UserDialog(user: user)))
        .then((_) {
          if (mounted) {
            ref.read(adminUsersPaginatedProvider.notifier).reset();
          }
        });
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteUserTitle),
        content: Text(AppLocalizations.of(context)!.deleteUserConfirm(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await adminDeleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.userDeleted)),
          );
          ref.read(adminUsersPaginatedProvider.notifier).reset();
        }
      } catch (e) {
        if (mounted) {
          final errStr = e.toString().toLowerCase();
          final isOffline =
              errStr.contains('socketexception') ||
              errStr.contains('failed host lookup') ||
              errStr.contains('connection refused') ||
              errStr.contains('clientexception') ||
              errStr.contains('network is unreachable') ||
              errStr.contains('xmlhttprequest error') ||
              errStr.contains('network error') ||
              errStr.contains('fetch failed') ||
              errStr.contains('offline');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOffline
                    ? 'You are offline. Please check your internet connection.'
                    : '${AppLocalizations.of(context)!.error}: $e',
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(adminUsersPaginatedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Client-side search filtering
    final allItems = pState.items;
    final filtered = _searchQuery.isEmpty
        ? allItems
        : allItems.where((u) {
            final email = (u['email'] as String? ?? '').toLowerCase();
            final name = (u['full_name'] as String? ?? '').toLowerCase();
            return email.contains(_searchQuery) || name.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageUsers),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminUsersPaginatedProvider.notifier).reset(),
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        onPressed: () => _showUserDialog(),
        icon: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.fill)),
        label: Text(AppLocalizations.of(context)!.addUser),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchUsers,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: pState.isInitialLoad
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(
                        5,
                        (_) => const ShimmerAdminTile(),
                      ),
                    ),
                  )
                : pState.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: OfflineWarningWidget(error: pState.error!),
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.users(),
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allItems.isEmpty
                              ? AppLocalizations.of(context)!.noUsersFound
                              : AppLocalizations.of(context)!.noMatchesFound,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length + (pState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: ShimmerAdminTile(),
                        );
                      }
                      final user = filtered[index];
                      final userRole = user['role'] as String? ?? 'user';
                      final isAdmin = userRole == 'admin';
                      final isContentCreator = userRole == 'content_creator';
                      final userPerms =
                          (user['permissions'] as List?)?.cast<String>() ?? [];
                      final hasCustomPerms =
                          userRole == 'user' && userPerms.isNotEmpty;
                      final lastSignIn = user['last_sign_in_at'] != null
                          ? DateTime.tryParse(user['last_sign_in_at'])
                          : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'])
                                : null,
                            child: user['avatar_url'] == null
                                ? Text(
                                    (user['full_name'] as String? ??
                                            user['email'] ??
                                            'U')[0]
                                        .toUpperCase(),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user['full_name'] ??
                                      AppLocalizations.of(context)!.noName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 6),
                                _roleBadge(
                                  AppLocalizations.of(
                                    context,
                                  )!.admin.toUpperCase(),
                                  const Color(0xFF6366F1),
                                ),
                              ],
                              if (isContentCreator) ...[
                                const SizedBox(width: 6),
                                _roleBadge(
                                  AppLocalizations.of(
                                    context,
                                  )!.roleContentCreator.toUpperCase(),
                                  const Color(0xFF8B5CF6),
                                ),
                              ],
                              if (hasCustomPerms) ...[
                                const SizedBox(width: 6),
                                _roleBadge(
                                  '${userPerms.length} ${AppLocalizations.of(context)!.permissionsLabel}',
                                  const Color(0xFF14B8A6),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'] ??
                                    AppLocalizations.of(context)!.noEmail,
                              ),
                              if (lastSignIn != null)
                                Text(
                                  AppLocalizations.of(context)!.lastLogin(
                                    DateFormat.yMMMd().add_jm().format(
                                      lastSignIn,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showUserDialog(user: user);
                              }
                              if (value == 'delete') {
                                _deleteUser(user['id'], user['email']);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.editChangeRole,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.deleteUserTitle,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;

  const _UserDialog({this.user});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  String _role = 'user';
  List<String> _selectedPermissions = [];
  bool _isLoading = false;

  bool get _isEditing => widget.user != null;

  // Section definitions for the permission grid
  static const _sectionDefs = [
    ('analytics', Icons.bar_chart, Color(0xFF6366F1)),
    ('suggestions', Icons.lightbulb_outline, Color(0xFF8B5CF6)),
    ('websites', Icons.language, Color(0xFF3B82F6)),
    ('categories', Icons.sell_outlined, Color(0xFF10B981)),
    ('notifications', Icons.notifications_active, Color(0xFFF59E0B)),
    ('in_app_messages', Icons.campaign, Color(0xFF14B8A6)),
    ('users', Icons.people_outline, Color(0xFFEC4899)),
    ('community', Icons.public, Color(0xFFEAB308)),
    ('advertisements', Icons.ad_units, Color(0xFF8B5CF6)),
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?['email']);
    _nameController = TextEditingController(text: widget.user?['full_name']);
    _passwordController = TextEditingController();
    _role = widget.user?['role'] ?? 'user';
    _selectedPermissions = List<String>.from(
      (widget.user?['permissions'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Determine the permissions to save
      List<String> permsToSave;
      if (_role == 'admin' || _role == 'content_creator') {
        permsToSave = []; // Permissions are implicit for these roles
      } else {
        permsToSave = _selectedPermissions;
      }

      if (_isEditing) {
        await adminUpdateUser(
          widget.user!['id'],
          role: _role,
          permissions: permsToSave,
        );
      } else {
        await adminCreateUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _role,
        );
        // If we just created a user with custom permissions, update them
        // (create doesn't support permissions in one go through the edge function)
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? AppLocalizations.of(context)!.userUpdated
                  : AppLocalizations.of(context)!.userCreated,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isOffline =
            errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('connection refused') ||
            errStr.contains('clientexception') ||
            errStr.contains('network is unreachable') ||
            errStr.contains('xmlhttprequest error') ||
            errStr.contains('network error') ||
            errStr.contains('fetch failed') ||
            errStr.contains('offline');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'You are offline. Please check your internet connection.'
                  : '${AppLocalizations.of(context)!.error}: $e',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _sectionLabel(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'analytics':
        return l.appActivities;
      case 'suggestions':
        return l.suggestionsTitle;
      case 'websites':
        return l.websitesTitle;
      case 'categories':
        return l.categoriesTitle;
      case 'notifications':
        return l.pushNotificationsTitle;
      case 'in_app_messages':
        return l.inAppMessagesTitle;
      case 'users':
        return l.usersTitle;
      case 'community':
        return l.communityTitle;
      case 'advertisements':
        return l.adminAdvertisementsTitle;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(_isEditing ? l.editUser : l.addUser),
        forceMaterialTransparency: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? l.save : l.create),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Account Details ──
            if (!_isEditing) ...[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? l.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: l.password),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? l.min6Chars : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l.fullName),
            ),

            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.emailPasswordChangeNote,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 28),

            // ── Role Section ──
            Text(
              l.roleLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),

            // Role cards
            _buildRoleCard(
              role: 'user',
              icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
              color: Colors.grey,
              title: l.user,
              subtitle: l.roleUserDesc,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              role: 'content_creator',
              icon: PhosphorIcons.pencilLine(PhosphorIconsStyle.duotone),
              color: const Color(0xFF8B5CF6),
              title: l.roleContentCreator,
              subtitle: l.roleContentCreatorDesc,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              role: 'admin',
              icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
              color: const Color(0xFF6366F1),
              title: l.admin,
              subtitle: l.roleAdminDesc,
              isDark: isDark,
            ),

            // ── Content Creator preset info ──
            if (_role == 'content_creator') ...[
              const SizedBox(height: 24),
              Text(
                l.presetPermissions.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kContentCreatorPermissions.map((key) {
                  return Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      color: const Color(0xFF8B5CF6),
                      size: 18,
                    ),
                    label: Text(_sectionLabel(context, key)),
                    backgroundColor: const Color(
                      0xFF8B5CF6,
                    ).withValues(alpha: 0.08),
                    side: BorderSide(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Custom Permissions (only when role is 'user') ──
            if (_role == 'user') ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.customPermissions.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  if (_selectedPermissions.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedPermissions.clear()),
                      child: Text(
                        l.clearAll,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.customPermissionsHint,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              ..._sectionDefs.map((def) {
                final key = def.$1;
                final icon = def.$2;
                final color = def.$3;
                final isSelected = _selectedPermissions.contains(key);

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: isSelected
                      ? color.withValues(alpha: 0.08)
                      : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPermissions.add(key);
                        } else {
                          _selectedPermissions.remove(key);
                        }
                      });
                    },
                    title: Text(
                      _sectionLabel(context, key),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : null,
                      ),
                    ),
                    secondary: Icon(
                      icon,
                      color: isSelected ? color : Colors.grey,
                    ),
                    activeColor: color,
                    controlAffinity: ListTileControlAffinity.trailing,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isSelected ? color : Colors.grey).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? color : Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
