import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_persona_model.dart';
import '../../data/services/zad_expert_service.dart';
import '../../presentation/providers/zad_expert_providers.dart';
import '../zad_expert/zad_expert_screen.dart' show hexToColor, personaIconFromName;
import '../zad_expert/widgets/persona_visual_options.dart';
import 'admin_ai_stats_tab.dart';
import 'admin_persona_modes_sheet.dart';
import '../../core/utils/admin_ui_utils.dart';

/// Currently-selected purpose filter in the Providers tab. The same admin
/// screen now manages providers for two distinct AI consumers (Zad Expert
/// personas + the general AI Assistant used by the discover "Understand
/// more" button, the embedded browser assistant, the Quick Tile and the
/// Zad Hub) — this provider lets the segmented control at the top of the
/// tab decide which set is displayed and which one new providers default
/// to. Kept private to this file because it's purely a UI concern.
final _providersPurposeFilterProvider =
    StateProvider<AiProviderPurpose>((ref) => AiProviderPurpose.zadExpert);

class AdminAiManagementScreen extends ConsumerStatefulWidget {
  const AdminAiManagementScreen({super.key});

  @override
  ConsumerState<AdminAiManagementScreen> createState() =>
      _AdminAiManagementScreenState();
}

class _AdminAiManagementScreenState
    extends ConsumerState<AdminAiManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.brain(PhosphorIconsStyle.fill),
                size: 22, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('إدارة الذكاء الاصطناعي',
                style: TextStyle()),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,  fontSize: 13),
          tabs: const [
            Tab(text: 'الشخصيات', icon: Icon(PhosphorIconsFill.robot, size: 18)),
            Tab(text: 'المزودين', icon: Icon(PhosphorIconsFill.plugs, size: 18)),
            Tab(text: 'الإحصائيات', icon: Icon(PhosphorIconsFill.chartLineUp, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PersonasTab(isDark: isDark),
          _ProvidersTab(isDark: isDark),
          AdminAiStatsTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1: Personas Management
// ═══════════════════════════════════════════════════════════════════════════════
class _PersonasTab extends ConsumerWidget {
  final bool isDark;
  const _PersonasTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(adminAllPersonasProvider);

    return personasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('خطأ: $e', style: const TextStyle()),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminAllPersonasProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (personas) {
        return Column(
          children: [
            Expanded(
              child: personas.isEmpty
                  ? Center(
                      child: Text('لا توجد شخصيات',
                          style: TextStyle(
                              
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: personas.length,
                      itemBuilder: (ctx, i) {
                        final p = personas[i];
                        final color = hexToColor(p.color);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkDivider
                                  : AppTheme.lightDivider,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(personaIconFromName(p.icon),
                                  color: Colors.white, size: 22),
                            ),
                            title: Text(p.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                            subtitle: Text(p.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Active indicator
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: p.isActive
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _PopupMenu(
                                  isDark: isDark,
                                  onEdit: () => _showPersonaEditor(
                                      context, ref, isDark, p),
                                  onDelete: () =>
                                      _deletePersona(context, ref, p),
                                  onToggle: () =>
                                      _togglePersona(ref, p),
                                  onManageModes: () =>
                                      AdminPersonaModesSheet.show(
                                          context, p, isDark),
                                  modesCount: p.modes.length,
                                  isActive: p.isActive,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (i * 60).ms, duration: 300.ms);
                      },
                    ),
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showPersonaEditor(context, ref, isDark, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(PhosphorIconsBold.plus, size: 18),
                  label: const Text('إضافة شخصية',
                      style: TextStyle()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPersonaEditor(BuildContext context, WidgetRef ref,
      bool isDark, AiPersonaModel? existing) async {
    List<AiProviderModel> providers = [];
    try {
      providers = await ref.read(adminAiProvidersProvider.future);
    } catch (e) {
      // Ignore and let empty check handle it
    }

    if (providers.isEmpty) {
      if (context.mounted) {
        AdminUIUtils.showWarning(context, 'يجب إضافة مزود أولاً');
      }
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final slugCtrl = TextEditingController(text: existing?.slug ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final instructionCtrl =
        TextEditingController(text: existing?.systemInstruction ?? '');
    final modelCtrl = TextEditingController(text: existing?.modelId ?? '');

    String selectedProviderId = existing?.providerId ?? providers.first.id;
    String selectedIcon = existing?.icon ?? 'robot';
    String selectedColor = existing?.color ?? '#6366F1';
    double temperature = existing?.temperature ?? 0.5;
    int maxTokens = existing?.maxTokens ?? 4096;
    bool isActive = existing?.isActive ?? true;
    // Mutable copy of quick actions so the modal can edit them locally.
    final List<Map<String, String>> quickActions = [
      for (final a in (existing?.quickActions ?? const <Map<String, String>>[]))
        {'label': a['label'] ?? '', 'prompt': a['prompt'] ?? ''}
    ];
    final newActionLabelCtrl = TextEditingController();
    final newActionPromptCtrl = TextEditingController();

    // Tool toggles — per-persona control over web search, URL reader, code exec.
    final List<String> enabledTools = List<String>.from(existing?.enabledTools ?? const []);

    if (!context.mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final mq = MediaQuery.of(ctx);
          final keyboard = mq.viewInsets.bottom;
          // When keyboard is open, shrink height so the modal doesn't get
          // pushed off-screen and clip the focused field.
          final maxH = mq.size.height * 0.88;
          final availableH = (mq.size.height - keyboard).clamp(0.0, maxH);
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Container(
              height: availableH,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing != null ? 'تعديل الشخصية' : 'شخصية جديدة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('إلغاء',
                                style: TextStyle(
                                    
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('حفظ',
                                style: TextStyle()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Form
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _field('الاسم', nameCtrl, isDark),
                      const SizedBox(height: 12),
                      _field('المعرف (slug)', slugCtrl, isDark,
                          hint: 'code-expert'),
                      const SizedBox(height: 12),
                      _field('الوصف', descCtrl, isDark, maxLines: 2),
                      const SizedBox(height: 16),

                      // Provider selector
                      _label('المزود', isDark),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkDivider
                                : AppTheme.lightDivider,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: selectedProviderId,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          dropdownColor:
                              isDark ? AppTheme.darkCard : Colors.white,
                          style: TextStyle(
                            
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          items: providers
                              .map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedProviderId = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(builder: (ctx) {
                        final currentProvider = providers.firstWhere((p) => p.id == selectedProviderId, orElse: () => providers.first);
                        final availableModels = currentProvider.supportedModels;
                        if (availableModels.isNotEmpty && !availableModels.contains(modelCtrl.text) && modelCtrl.text.isEmpty) {
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (ctx.mounted) setModalState(() => modelCtrl.text = availableModels.first);
                           });
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('النموذج (Model ID)', isDark),
                            const SizedBox(height: 6),
                            if (availableModels.isEmpty)
                              TextField(
                                controller: modelCtrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'llama-3.3-70b-versatile',
                                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider)),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                                ),
                                child: DropdownButton<String>(
                                  value: availableModels.contains(modelCtrl.text) ? modelCtrl.text : (availableModels.isNotEmpty ? availableModels.first : null),
                                  isExpanded: true,
                                  underline: const SizedBox.shrink(),
                                  dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                                  style: TextStyle( color: isDark ? Colors.white : Colors.black87),
                                  items: availableModels.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle()))).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() => modelCtrl.text = v);
                                    }
                                  },
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),

                      // Temperature
                      _label('Temperature: ${temperature.toStringAsFixed(2)}',
                          isDark),
                      Slider(
                        value: temperature,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) =>
                            setModalState(() => temperature = v),
                      ),
                      const SizedBox(height: 12),

                      // Max tokens
                      _label('الحد الأقصى للرد (tokens): $maxTokens', isDark),
                      Slider(
                        value: maxTokens.toDouble(),
                        min: 256,
                        max: 16384,
                        divisions: 32,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) =>
                            setModalState(() => maxTokens = v.toInt()),
                      ),
                      const SizedBox(height: 16),

                      // ── Live persona preview (reacts to name/desc) ──
                      ListenableBuilder(
                        listenable: Listenable.merge([nameCtrl, descCtrl]),
                        builder: (context, _) {
                        final c = hexToColor(selectedColor);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.withValues(alpha: isDark ? 0.18 : 0.10),
                                c.withValues(alpha: isDark ? 0.06 : 0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: c.withValues(alpha: 0.35), width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  c,
                                  c.withValues(alpha: 0.7),
                                ]),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(personaIconFromName(selectedIcon),
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameCtrl.text.trim().isEmpty
                                        ? 'اسم الشخصية'
                                        : nameCtrl.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    descCtrl.text.trim().isEmpty
                                        ? 'وصف مختصر للشخصية…'
                                        : descCtrl.text.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                      }),

                      // ── Visual icon picker (uses curated icon set) ─
                      _label('الأيقونة', isDark),
                      const SizedBox(height: 8),
                      PersonaIconPicker(
                        selected: selectedIcon,
                        highlight: hexToColor(selectedColor),
                        isDark: isDark,
                        onPick: (k) =>
                            setModalState(() => selectedIcon = k),
                      ),
                      const SizedBox(height: 16),

                      // ── Visual color palette ────────────────────
                      _label('اللون', isDark),
                      const SizedBox(height: 8),
                      PersonaColorPalette(
                        selected: selectedColor,
                        isDark: isDark,
                        onPick: (h) =>
                            setModalState(() => selectedColor = h),
                      ),
                      const SizedBox(height: 16),

                      // Active toggle
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) => setModalState(() => isActive = v),
                        title: Text('مفعّلة',
                            style: TextStyle(
                                
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Colors.black87)),
                        activeThumbColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // ── AI Tools per persona ──────────────────────────
                      _label('الأدوات المتاحة', isDark),
                      const SizedBox(height: 6),
                      _ToolToggle(
                        icon: Icons.search,
                        label: 'البحث في الإنترنت',
                        subtitle: 'web_search — بحث Jina AI',
                        value: enabledTools.contains('web_search'),
                        isDark: isDark,
                        onChanged: (v) => setModalState(() {
                          if (v) {
                            if (!enabledTools.contains('web_search')) enabledTools.add('web_search');
                          } else {
                            enabledTools.remove('web_search');
                          }
                        }),
                      ),
                      _ToolToggle(
                        icon: Icons.link,
                        label: 'قراءة الروابط',
                        subtitle: 'url_reader — Jina Reader',
                        value: enabledTools.contains('url_reader'),
                        isDark: isDark,
                        onChanged: (v) => setModalState(() {
                          if (v) {
                            if (!enabledTools.contains('url_reader')) enabledTools.add('url_reader');
                          } else {
                            enabledTools.remove('url_reader');
                          }
                        }),
                      ),
                      _ToolToggle(
                        icon: Icons.play_arrow_rounded,
                        label: 'تنفيذ الأكواد',
                        subtitle: 'code_exec — Judge0 CE',
                        value: enabledTools.contains('code_exec'),
                        isDark: isDark,
                        onChanged: (v) => setModalState(() {
                          if (v) {
                            if (!enabledTools.contains('code_exec')) enabledTools.add('code_exec');
                          } else {
                            enabledTools.remove('code_exec');
                          }
                        }),
                      ),
                      const SizedBox(height: 12),

                      // ── Quick actions (suggested prompts) ──
                      _label('الاقتراحات السريعة (تظهر للمستخدم عند فتح الشخصية)', isDark),
                      const SizedBox(height: 6),
                      if (quickActions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'لا توجد اقتراحات بعد. أضف اقتراحاً من الأسفل.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < quickActions.length; i++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.025),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quickActions[i]['label'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            quickActions[i]['prompt'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        PhosphorIcons.trash(),
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => setModalState(
                                          () => quickActions.removeAt(i)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: newActionLabelCtrl,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'العنوان (مثال: لخص هذه الصفحة)',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newActionPromptCtrl,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'الأمر الذي سيُملأ في صندوق الإدخال عند الضغط',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  final label = newActionLabelCtrl.text.trim();
                                  final prompt = newActionPromptCtrl.text.trim();
                                  if (label.isEmpty || prompt.isEmpty) return;
                                  setModalState(() {
                                    quickActions.add({
                                      'label': label,
                                      'prompt': prompt,
                                    });
                                    newActionLabelCtrl.clear();
                                    newActionPromptCtrl.clear();
                                  });
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('إضافة اقتراح'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // System instruction
                      _label('التعليمات النظامية (System Instruction)', isDark),
                      const SizedBox(height: 6),
                      TextField(
                        controller: instructionCtrl,
                        maxLines: 8,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'أنت خبير في...',
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.darkDivider
                                    : AppTheme.lightDivider),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      final persona = AiPersonaModel(
        id: existing?.id ?? '',
        name: nameCtrl.text.trim(),
        slug: slugCtrl.text.trim(),
        description: descCtrl.text.trim(),
        icon: selectedIcon,
        color: selectedColor,
        systemInstruction: instructionCtrl.text.trim(),
        providerId: selectedProviderId,
        modelId: modelCtrl.text.trim(),
        temperature: temperature,
        maxTokens: maxTokens,
        isActive: isActive,
        sortOrder: existing?.sortOrder ?? 0,
        quickActions: List<Map<String, String>>.from(quickActions),
        // Preserve sub-persona modes — they are managed in a dedicated sheet.
        modes: existing?.modes ?? const [],
        enabledTools: List<String>.from(enabledTools),
      );

      try {
        await ZadExpertService.savePersona(persona,
            existingId: existing?.id);
        ref.invalidate(adminAllPersonasProvider);
        ref.invalidate(expertPersonasProvider);
        if (context.mounted) {
          AdminUIUtils.showSuccess(context, 'تم حفظ الشخصية بنجاح');
        }
      } catch (e) {
        if (context.mounted) {
          AdminUIUtils.showError(context, 'فشل الحفظ: $e');
        }
      }
    }
  }

  Future<void> _deletePersona(
      BuildContext context, WidgetRef ref, AiPersonaModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الشخصية',
            style: TextStyle( fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl),
        content: Text('هل تريد حذف "${p.name}"؟',
            style: const TextStyle(),
            textDirection: TextDirection.rtl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style:
                      TextStyle( color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ZadExpertService.deletePersona(p.id);
      ref.invalidate(adminAllPersonasProvider);
      ref.invalidate(expertPersonasProvider);
    }
  }

  Future<void> _togglePersona(WidgetRef ref, AiPersonaModel p) async {
    final updated = AiPersonaModel(
      id: p.id,
      name: p.name,
      slug: p.slug,
      description: p.description,
      icon: p.icon,
      color: p.color,
      systemInstruction: p.systemInstruction,
      providerId: p.providerId,
      modelId: p.modelId,
      temperature: p.temperature,
      maxTokens: p.maxTokens,
      isActive: !p.isActive,
      sortOrder: p.sortOrder,
      quickActions: p.quickActions,
      modes: p.modes,
      enabledTools: p.enabledTools,
    );
    await ZadExpertService.savePersona(updated, existingId: p.id);
    ref.invalidate(adminAllPersonasProvider);
    ref.invalidate(expertPersonasProvider);
  }

  Widget _field(String label, TextEditingController ctrl, bool isDark,
      {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, isDark),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                      isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
          
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.black54),
      textDirection: TextDirection.rtl,
    );
  }
}

// ── Tool Toggle widget for persona editor ────────────────────────────────────
class _ToolToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToolToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = value ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
        secondary: Icon(icon, size: 20, color: accentColor),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2: Providers Management
// ═══════════════════════════════════════════════════════════════════════════════
class _ProvidersTab extends ConsumerWidget {
  final bool isDark;
  const _ProvidersTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(adminAiProvidersProvider);
    final filter = ref.watch(_providersPurposeFilterProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (allProviders) {
        // Group by purpose so the segmented control can show counts.
        final byPurpose = <AiProviderPurpose, List<AiProviderModel>>{};
        for (final p in allProviders) {
          byPurpose.putIfAbsent(p.purpose, () => []).add(p);
        }
        final providers = byPurpose[filter] ?? const <AiProviderModel>[];

        return Column(
          children: [
            // ─── Purpose switcher ────────────────────────────────────────
            // One screen, two distinct AI surfaces. The segmented control
            // makes it obvious which set is currently being managed and
            // also shows the count of providers per purpose so the admin
            // doesn't have to switch back and forth to remember.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<AiProviderPurpose>(
                segments: [
                  for (final purpose in AiProviderPurpose.values)
                    ButtonSegment(
                      value: purpose,
                      icon: Icon(
                        purpose == AiProviderPurpose.zadExpert
                            ? PhosphorIcons.graduationCap()
                            : PhosphorIcons.sparkle(),
                        size: 16,
                      ),
                      label: Text(
                        '${purpose.arabicLabel}'
                        ' (${(byPurpose[purpose] ?? const []).length})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
                selected: {filter},
                onSelectionChanged: (s) {
                  ref
                      .read(_providersPurposeFilterProvider.notifier)
                      .state = s.first;
                },
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
            ),
            // Helper caption explains what each purpose means at a glance.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Text(
                filter == AiProviderPurpose.zadExpert
                    ? 'مزودي خبير زاد — كل شخصية في الخبير تختار نموذجها الخاص. أضف مفاتيح API وأسماء النماذج المتاحة.'
                    : 'مزودي المساعد الذكي العام — يستخدمه زر "افهم أكثر" في المستكشف، المساعد المدمج في المتصفح، Quick Tile، وزاد المنسوخات. حدد نموذجاً واحداً لكل مزود.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            if (providers.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.plugsConnected(),
                          size: 56,
                          color:
                              (isDark ? Colors.white24 : Colors.black26)),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد مزودون مضافون لـ"${filter.arabicLabel}" بعد',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  itemCount: providers.length,
                  itemBuilder: (ctx, i) {
                    final p = providers[i];
                final hasKey = p.apiKey.isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.isActive
                            ? Colors.greenAccent.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        PhosphorIcons.plugs(PhosphorIconsStyle.fill),
                        color: p.isActive ? Colors.greenAccent : Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    title: Text(p.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            
                            color: isDark ? Colors.white : Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.slug,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              hasKey
                                  ? PhosphorIcons.key(PhosphorIconsStyle.fill)
                                  : PhosphorIcons.warning(),
                              size: 12,
                              color: hasKey
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasKey ? 'مفتاح مُعدّ' : 'لا يوجد مفتاح',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: hasKey
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _PopupMenu(
                      isDark: isDark,
                      isActive: p.isActive,
                      onEdit: () => _showProviderEditor(context, ref, isDark, p),
                      onDelete: () => _deleteProvider(context, ref, p),
                      onToggle: () => _toggleProvider(ref, p),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (i * 80).ms, duration: 300.ms);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showProviderEditor(
                      context, ref, isDark, null,
                      defaultPurpose: filter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(PhosphorIconsBold.plus, size: 18),
                  label: Text('إضافة مزود لـ${filter.arabicLabel}',
                      style: const TextStyle()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProviderEditor(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AiProviderModel? existing, {
    AiProviderPurpose defaultPurpose = AiProviderPurpose.zadExpert,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final slugCtrl = TextEditingController(text: existing?.slug ?? '');
    final urlCtrl = TextEditingController(text: existing?.baseUrl ?? '');

    // The purpose decides whether the "selected model" field is shown.
    // When creating a new provider it defaults to whichever segment the
    // admin is currently viewing — saves a click 99% of the time.
    AiProviderPurpose purpose = existing?.purpose ?? defaultPurpose;
    String? selectedModel = existing?.selectedModel;

    // API keys & models are now managed as chip lists for a much friendlier
    // input UX. We still persist them in the SAME shape the backend expects:
    //   • apiKey            → comma-joined string (the rotation/failover
    //                          logic on the edge function splits by ',')
    //   • supportedModels   → List<String>
    // So the load-balancing behaviour (try next key on error) is unchanged.
    final keys = <String>[
      ...?existing?.apiKey
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
    ];
    final models = <String>[...?existing?.supportedModels];

    bool isActive = existing?.isActive ?? true;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final mq = MediaQuery.of(ctx);
          final keyboard = mq.viewInsets.bottom;
          final maxH = mq.size.height * 0.75;
          final availableH = (mq.size.height - keyboard).clamp(0.0, maxH);
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Container(
              height: availableH,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null ? 'تعديل المزود' : 'مزود جديد',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('حفظ',
                            style: TextStyle()),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ─── Purpose picker ─────────────────────────────
                      // Letting the admin move a provider between Zad
                      // Expert and the general AI Assistant just by
                      // toggling this control is much friendlier than
                      // forcing them to delete-and-recreate.
                      Text('يخدم هذا المزود',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          )),
                      const SizedBox(height: 8),
                      SegmentedButton<AiProviderPurpose>(
                        segments: [
                          for (final p in AiProviderPurpose.values)
                            ButtonSegment(
                              value: p,
                              icon: Icon(
                                p == AiProviderPurpose.zadExpert
                                    ? PhosphorIcons.graduationCap()
                                    : PhosphorIcons.sparkle(),
                                size: 14,
                              ),
                              label: Text(p.arabicLabel,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                        selected: {purpose},
                        onSelectionChanged: (s) => setModalState(() {
                          purpose = s.first;
                          // When switching away from ai-assistant the
                          // selected model becomes irrelevant — clear it
                          // so we don't store stale state.
                          if (purpose != AiProviderPurpose.aiAssistant) {
                            selectedModel = null;
                          }
                        }),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primaryColor
                                  .withValues(alpha: 0.2);
                            }
                            return Colors.transparent;
                          }),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        purpose == AiProviderPurpose.zadExpert
                            ? 'كل شخصية في خبير زاد ستختار نموذجها بنفسها من قائمة "النماذج المدعومة" أدناه.'
                            : 'سيُستعمل هذا المزود في المساعد الذكي العام بنموذج واحد محدد. اختره أدناه.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _providerField('الاسم', nameCtrl, isDark),
                      const SizedBox(height: 12),
                      _providerField('المعرف (slug)', slugCtrl, isDark,
                          hint: 'groq'),
                      const SizedBox(height: 12),
                      _providerField('Base URL', urlCtrl, isDark,
                          hint: 'https://api.groq.com/openai/v1/chat/completions'),
                      const SizedBox(height: 12),
                      _ChipListInput(
                        label: 'مفاتيح API',
                        helper:
                            'أضف كل مفتاح بشكل منفصل. عند فشل أي مفتاح يتم الانتقال تلقائياً إلى التالي.',
                        hint: 'gsk_xxx',
                        addButtonText: 'إضافة مفتاح',
                        isDark: isDark,
                        isSecret: true,
                        values: keys,
                        onChanged: (v) => setModalState(() {
                          keys
                            ..clear()
                            ..addAll(v);
                        }),
                      ),
                      const SizedBox(height: 12),
                      _ChipListInput(
                        label: 'النماذج المدعومة',
                        helper: 'أضف كل نموذج بشكل منفصل.',
                        hint: 'llama-3.3-70b',
                        addButtonText: 'إضافة نموذج',
                        isDark: isDark,
                        values: models,
                        onChanged: (v) => setModalState(() {
                          models
                            ..clear()
                            ..addAll(v);
                          // If the previously-selected model was just
                          // deleted from the chip list, drop it so we
                          // don't persist a dangling reference.
                          if (selectedModel != null &&
                              !models.contains(selectedModel)) {
                            selectedModel = null;
                          }
                        }),
                      ),
                      // ─── Selected model (only for ai-assistant) ─────
                      // Zad Expert personas pick their own model per
                      // persona so this control is irrelevant for them.
                      if (purpose == AiProviderPurpose.aiAssistant) ...[
                        const SizedBox(height: 16),
                        Text('النموذج المستخدم في المساعد الذكي',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color:
                                  isDark ? Colors.white70 : Colors.black54,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          'اختر نموذجاً واحداً من قائمة "النماذج المدعومة" أعلاه. لو لم تختر شيئاً سيُستعمل أول نموذج تلقائياً.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (models.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.warning(),
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'أضف أسماء النماذج أولاً ثم اختر منها هنا.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue:
                                models.contains(selectedModel)
                                    ? selectedModel
                                    : (models.isNotEmpty
                                        ? models.first
                                        : null),
                            isExpanded: true,
                            dropdownColor: isDark
                                ? AppTheme.darkSurface
                                : Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? AppTheme.darkDivider
                                        : AppTheme.lightDivider),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                            ),
                            items: [
                              for (final m in models)
                                DropdownMenuItem(
                                  value: m,
                                  child: Text(m,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 13)),
                                ),
                            ],
                            onChanged: (v) =>
                                setModalState(() => selectedModel = v),
                          ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) =>
                            setModalState(() => isActive = v),
                        title: Text('مفعّل',
                            style: TextStyle(
                                
                                color:
                                    isDark ? Colors.white : Colors.black87)),
                        activeThumbColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      // Persist in the legacy format the backend expects: keys joined by ','
      // (the edge function splits on ',' for round-robin / failover) and
      // models as a list. The UI only changed; the rotation logic is intact.
      final cleanedKeys =
          keys.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final cleanedModels =
          models.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Final selected_model resolution:
      //   * For zad-expert: always null (per-persona model takes over).
      //   * For ai-assistant: keep the chosen model only if it still
      //     exists in the cleaned model list, else null (= "use first").
      final String? finalSelectedModel =
          purpose == AiProviderPurpose.aiAssistant &&
                  selectedModel != null &&
                  cleanedModels.contains(selectedModel)
              ? selectedModel
              : null;

      final provider = AiProviderModel(
        id: existing?.id ?? '',
        name: nameCtrl.text.trim(),
        slug: slugCtrl.text.trim(),
        baseUrl: urlCtrl.text.trim(),
        apiKey: cleanedKeys.join(','),
        isActive: isActive,
        supportedModels: cleanedModels,
        purpose: purpose,
        selectedModel: finalSelectedModel,
      );

      try {
        await ZadExpertService.saveProvider(provider,
            existingId: existing?.id);
        ref.invalidate(adminAiProvidersProvider);
        if (context.mounted) {
          AdminUIUtils.showSuccess(context, 'تم حفظ المزود بنجاح');
        }
      } catch (e) {
        if (context.mounted) {
          AdminUIUtils.showError(context, 'فشل الحفظ: $e');
        }
      }
    }
  }

  Future<void> _deleteProvider(
      BuildContext context, WidgetRef ref, AiProviderModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المزود',
            style: TextStyle( fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl),
        content: Text('هل تريد حذف "${p.name}"؟\nسيؤدي هذا إلى تعطل الشخصيات المرتبطة به إن وجدت.',
            style: const TextStyle(),
            textDirection: TextDirection.rtl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style:
                      TextStyle( color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ZadExpertService.deleteProvider(p.id);
      ref.invalidate(adminAiProvidersProvider);
    }
  }

  Future<void> _toggleProvider(WidgetRef ref, AiProviderModel p) async {
    // Use copyWith so we never accidentally drop purpose or selected_model
    // when toggling active state — that would silently break the routing
    // of which AI consumer this provider serves.
    final updated = p.copyWith(isActive: !p.isActive);
    await ZadExpertService.saveProvider(updated, existingId: p.id);
    ref.invalidate(adminAiProvidersProvider);
  }

  Widget _providerField(
      String label, TextEditingController ctrl, bool isDark,
      {String? hint, bool isSecret = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: isSecret,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                      isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Popup Menu
// ═══════════════════════════════════════════════════════════════════════════════
class _PopupMenu extends StatelessWidget {
  final bool isDark;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback? onManageModes;
  final int modesCount;

  const _PopupMenu({
    required this.isDark,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    this.onManageModes,
    this.modesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(PhosphorIcons.dotsThreeVertical(),
          color: isDark ? Colors.white54 : Colors.black45, size: 20),
      color: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
            break;
          case 'modes':
            onManageModes?.call();
            break;
          case 'toggle':
            onToggle();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(PhosphorIcons.pencilSimple(), size: 16),
              const SizedBox(width: 8),
              const Text('تعديل', style: TextStyle())
            ])),
        if (onManageModes != null)
          PopupMenuItem(
              value: 'modes',
              child: Row(children: [
                Icon(PhosphorIcons.squaresFour(), size: 16),
                const SizedBox(width: 8),
                Text('إدارة الأوضاع${modesCount > 0 ? ' ($modesCount)' : ''}',
                    style: const TextStyle())
              ])),
        PopupMenuItem(
            value: 'toggle',
            child: Row(children: [
              Icon(isActive ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
                  size: 16),
              const SizedBox(width: 8),
              Text(isActive ? 'تعطيل' : 'تفعيل',
                  style: const TextStyle())
            ])),
        PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              const Icon(PhosphorIconsFill.trash,
                  size: 16, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text('حذف',
                  style:
                      TextStyle( color: Colors.redAccent))
            ])),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Chip-list input — friendlier UX for entering API keys & model names
// ═══════════════════════════════════════════════════════════════════════════════
//
// Renders the existing entries as chips (each with its own delete X) and
// provides a single text field + "+" button to add a new one. Pressing
// Enter in the text field also adds the entry. If the user pastes a string
// that contains commas, we split on ',' and add each piece — this preserves
// muscle memory for admins who used to paste bulk values, while making the
// common case (typing one item at a time) much nicer.
//
// API-key chips are displayed masked (e.g. `••••••abcd`) so secrets are not
// exposed on screen; tapping the eye toggles full visibility temporarily.
// The data model (List<String>) is the same regardless of `isSecret`, so
// the parent simply joins keys with ',' before saving — exactly matching
// the format the edge function already splits on for round-robin/failover.
class _ChipListInput extends StatefulWidget {
  final String label;
  final String? helper;
  final String? hint;
  final String addButtonText;
  final bool isDark;
  final bool isSecret;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const _ChipListInput({
    required this.label,
    required this.addButtonText,
    required this.isDark,
    required this.values,
    required this.onChanged,
    this.helper,
    this.hint,
    this.isSecret = false,
  });

  @override
  State<_ChipListInput> createState() => _ChipListInputState();
}

class _ChipListInputState extends State<_ChipListInput> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _revealSecrets = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit([String? raw]) {
    final text = (raw ?? _ctrl.text);
    if (text.trim().isEmpty) return;

    // Allow paste-with-commas: split on ',' so admins can still bulk-paste.
    final pieces = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (pieces.isEmpty) return;

    final next = [...widget.values];
    for (final p in pieces) {
      if (!next.contains(p)) next.add(p);
    }
    widget.onChanged(next);
    _ctrl.clear();
    _focus.requestFocus();
  }

  void _remove(int index) {
    final next = [...widget.values]..removeAt(index);
    widget.onChanged(next);
  }

  String _maskSecret(String s) {
    if (!widget.isSecret || _revealSecrets) return s;
    if (s.length <= 4) return '•' * s.length;
    return '${'•' * (s.length - 4).clamp(4, 10)}${s.substring(s.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor =
        isDark ? AppTheme.darkDivider : AppTheme.lightDivider;
    final accent = AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54),
                textDirection: TextDirection.rtl,
              ),
            ),
            // Count badge — quick visual cue of how many items are configured.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.values.length}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent),
              ),
            ),
            if (widget.isSecret) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () =>
                    setState(() => _revealSecrets = !_revealSecrets),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _revealSecrets
                        ? PhosphorIcons.eyeSlash()
                        : PhosphorIcons.eye(),
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helper!,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black45,
                height: 1.4),
            textDirection: TextDirection.rtl,
          ),
        ],
        const SizedBox(height: 8),

        // ── Chips ──────────────────────────────────────────────────────
        if (widget.values.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < widget.values.length; i++)
                  _Chip(
                    // Numbered prefix makes it clear which key/model is in
                    // which slot — useful for admins debugging rotation order.
                    label: '${i + 1}. ${_maskSecret(widget.values[i])}',
                    isDark: isDark,
                    onRemove: () => _remove(i),
                  ),
              ],
            ),
          ),
        if (widget.values.isNotEmpty) const SizedBox(height: 8),

        // ── Add row ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                obscureText: widget.isSecret && !_revealSecrets,
                textInputAction: TextInputAction.done,
                onSubmitted: _commit,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26),
                  filled: true,
                  fillColor: fillColor,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: accent, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _commit(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsBold.plus,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        widget.addButtonText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  const _Chip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.primaryColor.withValues(alpha: 0.10);
    final fg = isDark ? Colors.white : const Color(0xFF5B21B6);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                size: 14,
                color: isDark ? Colors.white70 : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
