import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import 'coach_mark.dart';
import '../../l10n/app_localizations.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;
  final bool isPointer;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
    this.isPointer = false,
  });
}

enum TutorialSection { clipboard, pages, browser, discover }

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final TutorialSection section;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.section,
  });

  static void show(
    BuildContext context, {
    required TutorialSection section,
    required List<TutorialStep> steps,
    required VoidCallback onComplete,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        section: section,
        steps: steps,
        onComplete: () {
          onComplete();
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  Future<void> _complete() async {
    await TutorialManager.markSectionSeen(widget.section);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (step.isPointer)
            CoachMark(
              title: step.title,
              description: step.description,
              targetKey: step.targetKey,
              currentStep: _currentStep,
              totalSteps: widget.steps.length,
              isLast: _currentStep == widget.steps.length - 1,
              onNext: _nextStep,
              onSkip: _skip,
            ).animate().fadeIn(duration: 300.ms)
          else
            // Default centered card for intro/outro steps
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1E1E2E) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(step.icon, size: 36, color: AppTheme.primaryColor),
                      ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black54,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.tutSkip,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              _currentStep == widget.steps.length - 1 
                                  ? AppLocalizations.of(context)!.tutStart 
                                  : AppLocalizations.of(context)!.tutNext,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic),
              ),
            ),
        ],
      ),
    );
  }
}

class TutorialManager {
  static Future<bool> shouldShowSection(TutorialSection section) async {
    final settings = SettingsRepository();
    final data = settings.getAllSettings();
    
    switch (section) {
      case TutorialSection.clipboard:
        return !(data['hasSeenClipboardTutorial'] as bool? ?? false);
      case TutorialSection.pages:
        return !(data['hasSeenPagesTutorial'] as bool? ?? false);
      case TutorialSection.browser:
        return !(data['hasSeenBrowserTutorial'] as bool? ?? false);
      case TutorialSection.discover:
        return !(data['hasSeenDiscoverTutorial'] as bool? ?? false);
    }
  }

  static Future<void> markSectionSeen(TutorialSection section) async {
    final settings = SettingsRepository();
    switch (section) {
      case TutorialSection.clipboard:
        await settings.setHasSeenClipboardTutorial(true);
        break;
      case TutorialSection.pages:
        await settings.setHasSeenPagesTutorial(true);
        break;
      case TutorialSection.browser:
        await settings.setHasSeenBrowserTutorial(true);
        break;
      case TutorialSection.discover:
        await settings.setHasSeenDiscoverTutorial(true);
        break;
    }
  }

   static List<TutorialStep> getClipboardSteps(AppLocalizations l10n, GlobalKey? fabKey, GlobalKey? firstItemKey, GlobalKey? groupsBarKey) {
    return [
      TutorialStep(
        title: l10n.tutClipboardWelcomeTitle,
        description: l10n.tutClipboardWelcomeDesc,
        icon: PhosphorIcons.sparkle(),
      ),
      TutorialStep(
        title: l10n.tutClipboardAddTitle,
        description: l10n.tutClipboardAddDesc,
        icon: PhosphorIcons.plus(),
        targetKey: fabKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutClipboardEditTitle,
        description: l10n.tutClipboardEditDesc,
        icon: PhosphorIcons.pencilSimple(),
        targetKey: firstItemKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutClipboardGroupsTitle,
        description: l10n.tutClipboardGroupsDesc,
        icon: PhosphorIcons.folder(),
        targetKey: groupsBarKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutClipboardMultiTitle,
        description: l10n.tutClipboardMultiDesc,
        icon: PhosphorIcons.checkSquare(),
        targetKey: firstItemKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutClipboardDeleteTitle,
        description: l10n.tutClipboardDeleteDesc,
        icon: PhosphorIcons.trash(),
      ),
    ];
  }

   static List<TutorialStep> getPagesSteps(AppLocalizations l10n, GlobalKey? fabKey, GlobalKey? folderKey) {
    return [
      TutorialStep(
        title: l10n.tutPagesWelcomeTitle,
        description: l10n.tutPagesWelcomeDesc,
        icon: PhosphorIcons.globe(),
      ),
      TutorialStep(
        title: l10n.tutPagesAddTitle,
        description: l10n.tutPagesAddDesc,
        icon: PhosphorIcons.plus(),
        targetKey: fabKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutPagesFoldersTitle,
        description: l10n.tutPagesFoldersDesc,
        icon: PhosphorIcons.folder(),
        targetKey: folderKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutPagesManageTitle,
        description: l10n.tutPagesManageDesc,
        icon: PhosphorIcons.trash(),
      ),
    ];
  }

   static List<TutorialStep> getBrowserSteps(AppLocalizations l10n, GlobalKey? clipboardKey, GlobalKey? suggestKey, GlobalKey? aiKey) {
    return [
      TutorialStep(
        title: l10n.tutBrowserWelcomeTitle,
        description: l10n.tutBrowserWelcomeDesc,
        icon: PhosphorIcons.browsers(),
      ),
      TutorialStep(
        title: l10n.tutBrowserFloatingTitle,
        description: l10n.tutBrowserFloatingDesc,
        icon: PhosphorIcons.clipboardText(),
        targetKey: clipboardKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutBrowserAiAssistantTitle,
        description: l10n.tutBrowserAiAssistantDesc,
        icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
        targetKey: aiKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutBrowserSuggestTitle,
        description: l10n.tutBrowserSuggestDesc,
        icon: PhosphorIcons.paperPlaneTilt(),
        targetKey: suggestKey,
        isPointer: true,
      ),
    ];
  }

  static List<TutorialStep> getDiscoverSteps(AppLocalizations l10n, GlobalKey? aiKey, GlobalKey? clipboardKey, GlobalKey? saveKey) {
    return [
      TutorialStep(
        title: l10n.tutDiscoverWelcomeTitle,
        description: l10n.tutDiscoverWelcomeDesc,
        icon: PhosphorIcons.compass(),
      ),
      TutorialStep(
        title: l10n.tutBrowserAiAssistantTitle,
        description: l10n.tutBrowserAiAssistantDesc,
        icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
        targetKey: aiKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutBrowserFloatingTitle,
        description: l10n.tutBrowserFloatingDesc,
        icon: PhosphorIcons.clipboardText(),
        targetKey: clipboardKey,
        isPointer: true,
      ),
      TutorialStep(
        title: l10n.tutDiscoverSaveTitle,
        description: l10n.tutDiscoverSaveDesc,
        icon: PhosphorIcons.folderPlus(),
        targetKey: saveKey,
        isPointer: true,
      ),
    ];
  }
}