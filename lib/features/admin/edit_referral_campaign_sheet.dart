import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/referral_model.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../presentation/providers/events_providers.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../core/supabase_config.dart';
import '../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════
//  CREATE / EDIT REFERRAL CAMPAIGN
// ═══════════════════════════════════════════

class EditReferralCampaignSheet extends ConsumerStatefulWidget {
  final ReferralCampaign? campaign;
  const EditReferralCampaignSheet({super.key, this.campaign});

  @override
  ConsumerState<EditReferralCampaignSheet> createState() =>
      _EditReferralCampaignSheetState();
}

class _EditReferralCampaignSheetState
    extends ConsumerState<EditReferralCampaignSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _rewardDescCtrl;
  late final TextEditingController _referredRewardDescCtrl;
  late int _requiredReferrals;
  late String _rewardType;
  String? _rewardGiveawayId;
  String? _rewardCollectionId;
  late String _referredRewardType;
  late bool _isActive;
  late bool _isVisible;
  DateTime? _endsAt;
  bool _saving = false;

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _rewardDescCtrl = TextEditingController(text: c?.rewardDescription ?? '');
    _referredRewardDescCtrl = TextEditingController(
      text: c?.referredRewardDescription ?? '',
    );
    _requiredReferrals = c?.requiredReferrals ?? 3;
    _rewardType = c?.rewardType ?? 'none';
    _rewardGiveawayId = c?.rewardGiveawayId;
    _rewardCollectionId = c?.rewardCollectionId;
    _referredRewardType = c?.referredRewardType ?? 'none';
    _isActive = c?.isActive ?? false;
    _isVisible = c?.isVisible ?? false;
    _endsAt = c?.endsAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardDescCtrl.dispose();
    _referredRewardDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.referralEditCampaign : l10n.referralCreateCampaign,
        ),
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            _buildTextField(
              controller: _titleCtrl,
              label: l10n.referralCampaignTitle,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // ── Description ──
            _buildTextField(
              controller: _descCtrl,
              label: l10n.referralCampaignDesc,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // ── Required referrals ──
            _buildSectionTitle(l10n.referralRequiredCount, isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _requiredReferrals > 1
                      ? () => setState(() => _requiredReferrals--)
                      : null,
                  icon: Icon(PhosphorIcons.minus(), size: 20),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_requiredReferrals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _requiredReferrals++),
                  icon: Icon(PhosphorIcons.plus(), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Reward Type ──
            _buildSectionTitle(l10n.referralRewardType, isDark),
            const SizedBox(height: 8),
            ..._buildRewardTypeOptions(l10n, isDark),
            const SizedBox(height: 16),

            // ── Reward-specific fields ──
            if (_rewardType == 'giveaway_entry' ||
                _rewardType == 'giveaway_boost')
              _buildGiveawaySelector(l10n, isDark),

            if (_rewardType == 'collection_access')
              _buildCollectionSelector(l10n, isDark),

            if (_rewardType == 'custom') ...[
              _buildTextField(
                controller: _rewardDescCtrl,
                label: l10n.referralRewardDescription,
                hint: l10n.referralRewardDescHint,
                isDark: isDark,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // ── Referred user reward ──
            const SizedBox(height: 8),
            _buildSectionTitle(l10n.referralReferredReward, isDark),
            const SizedBox(height: 8),
            _buildToggleOption(
              label: l10n.referralReferredRewardDesc,
              value: _referredRewardType == 'giveaway_entry',
              onChanged: (v) {
                setState(() {
                  _referredRewardType = v ? 'giveaway_entry' : 'none';
                });
              },
              isDark: isDark,
            ),
            if (_referredRewardType != 'none') ...[
              const SizedBox(height: 8),
              _buildTextField(
                controller: _referredRewardDescCtrl,
                label: l10n.referralReferredRewardDescHint,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 20),

            // ── End date ──
            _buildSectionTitle(l10n.referralEndsAt, isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickEndDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.calendar(),
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _endsAt != null
                          ? '${_endsAt!.day}/${_endsAt!.month}/${_endsAt!.year}'
                          : l10n.referralEndsAt,
                      style: TextStyle(
                        color: _endsAt != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    if (_endsAt != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _endsAt = null),
                        child: Icon(
                          PhosphorIcons.x(),
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Active / Visible toggles ──
            _buildSectionTitle(l10n.referralSettings, isDark),
            const SizedBox(height: 8),
            _buildToggleOption(
              label: l10n.referralActive,
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildToggleOption(
              label: l10n.referralVisibleSub,
              value: _isVisible,
              onChanged: (v) => setState(() => _isVisible = v),
              isDark: isDark,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? l10n.saveChanges : l10n.referralCreateCampaign,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRewardTypeOptions(AppLocalizations l10n, bool isDark) {
    final options = [
      ('none', l10n.referralRewardNone, PhosphorIcons.prohibit()),
      (
        'giveaway_entry',
        l10n.referralRewardGiveawayEntry,
        PhosphorIcons.ticket(),
      ),
      (
        'giveaway_boost',
        l10n.referralRewardGiveawayBoost,
        PhosphorIcons.lightning(),
      ),
      (
        'collection_access',
        l10n.referralRewardCollectionAccess,
        PhosphorIcons.lock(),
      ),
      ('custom', l10n.referralRewardCustom, PhosphorIcons.star()),
    ];

    return options.map((opt) {
      final selected = _rewardType == opt.$1;
      return GestureDetector(
        onTap: () => setState(() => _rewardType = opt.$1),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : isDark
                  ? AppTheme.darkDivider
                  : AppTheme.lightDivider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                opt.$3,
                size: 20,
                color: selected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 12),
              Text(
                opt.$2,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGiveawaySelector(AppLocalizations l10n, bool isDark) {
    final giveawaysAsync = ref.watch(giveawaysProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.referralSelectGiveaway, isDark),
        const SizedBox(height: 8),
        giveawaysAsync.when(
          data: (giveaways) {
            final activeGiveaways = giveaways.where((g) => g.isActive).toList();
            if (activeGiveaways.isEmpty) {
              return Text(
                'No active giveaways',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              );
            }
            return Column(
              children: activeGiveaways.map((g) {
                final selected = _rewardGiveawayId == g.id;
                return GestureDetector(
                  onTap: () => setState(() => _rewardGiveawayId = g.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.gift(),
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(g.title)),
                        if (selected)
                          Icon(
                            PhosphorIcons.check(),
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const SizedBox(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCollectionSelector(AppLocalizations l10n, bool isDark) {
    final collectionsAsync = ref.watch(adminCollectionsProvider);
    // Replace localization string if it doesn't exist, we fallback
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.referralSelectCollection, isDark),
        const SizedBox(height: 8),
        collectionsAsync.when(
          data: (collections) {
            if (collections.isEmpty) {
              return Text(
                'No collections available',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              );
            }
            return Column(
              children: collections.map((c) {
                final selected = _rewardCollectionId == c.id;
                return GestureDetector(
                  onTap: () => setState(() => _rewardCollectionId = c.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.folder(),
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.title)),
                        if (selected)
                          Icon(
                            PhosphorIcons.check(),
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const SizedBox(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool isDark,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endsAt = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'is_active': _isActive,
        'is_visible': _isVisible,
        'required_referrals': _requiredReferrals,
        'reward_type': _rewardType,
        'reward_giveaway_id':
            (_rewardType == 'giveaway_entry' || _rewardType == 'giveaway_boost')
            ? _rewardGiveawayId
            : null,
        'reward_collection_id': _rewardType == 'collection_access'
            ? _rewardCollectionId
            : null,
        'reward_description': _rewardDescCtrl.text.trim().isEmpty
            ? null
            : _rewardDescCtrl.text.trim(),
        'referred_reward_type': _referredRewardType,
        'referred_reward_description':
            _referredRewardDescCtrl.text.trim().isEmpty
            ? null
            : _referredRewardDescCtrl.text.trim(),
        'ends_at': _endsAt?.toUtc().toIso8601String(),
      };

      if (_isEditing) {
        await updateReferralCampaign(widget.campaign!.id, data, ref);
        if (_rewardType == 'collection_access' && _rewardCollectionId != null) {
          await SupabaseConfig.client
              .from('featured_collections')
              .update({'is_referral_exclusive': true})
              .eq('id', _rewardCollectionId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.referralCampaignUpdated)));
          Navigator.pop(context);
        }
      } else {
        await createReferralCampaign(data, ref);
        if (_rewardType == 'collection_access' && _rewardCollectionId != null) {
          await SupabaseConfig.client
              .from('featured_collections')
              .update({'is_referral_exclusive': true})
              .eq('id', _rewardCollectionId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.referralCampaignCreated)));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
