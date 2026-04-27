import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_persona_model.dart';
import '../../data/services/zad_expert_service.dart';
import '../../presentation/providers/zad_expert_providers.dart';
import '../zad_expert/zad_expert_screen.dart' show hexToColor, personaIconFromName;

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
    _tabController = TabController(length: 2, vsync: this);
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
                size: 22, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            const Text('إدارة الذكاء الاصطناعي',
                style: TextStyle()),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor:
              isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,  fontSize: 13),
          tabs: const [
            Tab(text: 'الشخصيات', icon: Icon(PhosphorIconsFill.robot, size: 18)),
            Tab(text: 'المزودين', icon: Icon(PhosphorIconsFill.plugs, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PersonasTab(isDark: isDark),
          _ProvidersTab(isDark: isDark),
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
                    backgroundColor: const Color(0xFF8B5CF6),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يجب إضافة مزود أولاً',
                  style: TextStyle()),
              backgroundColor: Colors.redAccent),
        );
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
                              backgroundColor: const Color(0xFF8B5CF6),
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
                        activeColor: const Color(0xFF8B5CF6),
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
                        activeColor: const Color(0xFF8B5CF6),
                        onChanged: (v) =>
                            setModalState(() => maxTokens = v.toInt()),
                      ),
                      const SizedBox(height: 16),

                      // Icon & Color
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('الأيقونة', isDark),
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
                                    value: selectedIcon,
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    dropdownColor: isDark
                                        ? AppTheme.darkCard
                                        : Colors.white,
                                    items: [
                                      DropdownMenuItem(value: 'robot', child: Row(children: [Icon(PhosphorIcons.robot(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('روبوت')])),
                                      DropdownMenuItem(value: 'code', child: Row(children: [Icon(PhosphorIcons.code(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('كود')])),
                                      DropdownMenuItem(value: 'paintBrush', child: Row(children: [Icon(PhosphorIcons.paintBrush(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('فرشاة')])),
                                      DropdownMenuItem(value: 'pencilLine', child: Row(children: [Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('قلم')])),
                                      DropdownMenuItem(value: 'magic', child: Row(children: [Icon(PhosphorIcons.magicWand(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('سحر')])),
                                      DropdownMenuItem(value: 'brain', child: Row(children: [Icon(PhosphorIcons.brain(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('دماغ')])),
                                      DropdownMenuItem(value: 'lightbulb', child: Row(children: [Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('فكرة')])),
                                      DropdownMenuItem(value: 'graduationCap', child: Row(children: [Icon(PhosphorIcons.graduationCap(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('تعليم')])),
                                      DropdownMenuItem(value: 'chart', child: Row(children: [Icon(PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('مخطط')])),
                                      DropdownMenuItem(value: 'treeStructure', child: Row(children: [Icon(PhosphorIcons.treeStructure(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('هيكل')])),
                                      DropdownMenuItem(value: 'flow', child: Row(children: [Icon(PhosphorIcons.flowArrow(PhosphorIconsStyle.fill), size: 18, color: isDark ? Colors.white70 : Colors.black54), const SizedBox(width: 8), const Text('تدفق')])),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setModalState(() => selectedIcon = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('اللون', isDark),
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
                                    value: selectedColor,
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    dropdownColor: isDark
                                        ? AppTheme.darkCard
                                        : Colors.white,
                                    items: [
                                      DropdownMenuItem(value: '#6366F1', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#6366F1'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('بنفسجي')])),
                                      DropdownMenuItem(value: '#EC4899', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#EC4899'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('وردي')])),
                                      DropdownMenuItem(value: '#F59E0B', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#F59E0B'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('ذهبي')])),
                                      DropdownMenuItem(value: '#10B981', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#10B981'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('أخضر')])),
                                      DropdownMenuItem(value: '#8B5CF6', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#8B5CF6'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('أرجواني')])),
                                      DropdownMenuItem(value: '#EF4444', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#EF4444'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('أحمر')])),
                                      DropdownMenuItem(value: '#3B82F6', child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: hexToColor('#3B82F6'), shape: BoxShape.circle)), const SizedBox(width: 8), const Text('أزرق')])),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setModalState(() => selectedColor = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        activeThumbColor: const Color(0xFF8B5CF6),
                        contentPadding: EdgeInsets.zero,
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
                                      color: const Color(0xFF8B5CF6),
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
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
                                  backgroundColor: const Color(0xFF8B5CF6),
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
      );

      try {
        await ZadExpertService.savePersona(persona,
            existingId: existing?.id);
        ref.invalidate(adminAllPersonasProvider);
        ref.invalidate(expertPersonasProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم الحفظ بنجاح ✅',
                  style: TextStyle()),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e', style: const TextStyle()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
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

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2: Providers Management
// ═══════════════════════════════════════════════════════════════════════════════
class _ProvidersTab extends ConsumerWidget {
  final bool isDark;
  const _ProvidersTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(adminAiProvidersProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (providers) => Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showProviderEditor(context, ref, isDark, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(PhosphorIconsBold.plus, size: 18),
                label: const Text('إضافة مزود',
                    style: TextStyle()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProviderEditor(BuildContext context, WidgetRef ref,
      bool isDark, AiProviderModel? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final slugCtrl = TextEditingController(text: existing?.slug ?? '');
    final urlCtrl = TextEditingController(text: existing?.baseUrl ?? '');
    final keyCtrl = TextEditingController(text: existing?.apiKey ?? '');
    final modelsCtrl = TextEditingController(
        text: existing?.supportedModels.join(', ') ?? '');
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
                          backgroundColor: const Color(0xFF8B5CF6),
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
                      _providerField('الاسم', nameCtrl, isDark),
                      const SizedBox(height: 12),
                      _providerField('المعرف (slug)', slugCtrl, isDark,
                          hint: 'groq'),
                      const SizedBox(height: 12),
                      _providerField('Base URL', urlCtrl, isDark,
                          hint: 'https://api.groq.com/openai/v1/chat/completions'),
                      const SizedBox(height: 12),
                      _providerField('API Key (متعددة بفاصلة)', keyCtrl, isDark,
                          hint: 'gsk_xxx,gsk_yyy', isSecret: true),
                      const SizedBox(height: 12),
                      _providerField(
                          'النماذج المدعومة (بفاصلة)', modelsCtrl, isDark,
                          hint: 'llama-3.3-70b, mixtral-8x7b'),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) =>
                            setModalState(() => isActive = v),
                        title: Text('مفعّل',
                            style: TextStyle(
                                
                                color:
                                    isDark ? Colors.white : Colors.black87)),
                        activeThumbColor: const Color(0xFF8B5CF6),
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
      final models = modelsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final provider = AiProviderModel(
        id: existing?.id ?? '',
        name: nameCtrl.text.trim(),
        slug: slugCtrl.text.trim(),
        baseUrl: urlCtrl.text.trim(),
        apiKey: keyCtrl.text.trim(),
        isActive: isActive,
        supportedModels: models,
      );

      try {
        await ZadExpertService.saveProvider(provider,
            existingId: existing?.id);
        ref.invalidate(adminAiProvidersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم الحفظ ✅',
                  style: TextStyle()),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
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
    final updated = AiProviderModel(
      id: p.id,
      name: p.name,
      slug: p.slug,
      baseUrl: p.baseUrl,
      apiKey: p.apiKey,
      supportedModels: p.supportedModels,
      isActive: !p.isActive,
    );
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

  const _PopupMenu({
    required this.isDark,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
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
