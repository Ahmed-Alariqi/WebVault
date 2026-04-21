import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/ai_assistant_providers.dart';
import 'ai_chat_screen.dart';

class AiChatBottomSheet extends ConsumerWidget {
  final WebsiteModel site;

  const AiChatBottomSheet({
    super.key,
    required this.site,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiBottomSheetStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Total available height relative to the screen
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Define heights for folded vs expanded states
    final expandedHeight = screenHeight * 0.85; 
    final foldedHeight = screenHeight * 0.5;

    // Use total screen height for positioning offset
    final currentHeight = state.isExpanded ? expandedHeight : foldedHeight;

    if (!state.isVisible) {
      return const SizedBox.shrink(); // Totally hidden and off-tree
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      bottom: state.isVisible ? 0 : -expandedHeight - 100,
      left: 0,
      right: 0,
      height: currentHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          // Drag down to close or fold, drag up to expand
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 800) { // Fast swipe down
            if (state.isExpanded) {
               ref.read(aiBottomSheetStateProvider.notifier).state = 
                 const AiBottomSheetState(isVisible: true, isExpanded: false);
            } else {
               ref.read(aiBottomSheetStateProvider.notifier).state = 
                 const AiBottomSheetState(isVisible: false, isExpanded: false);
            }
          } else if (velocity < -800) { // Fast swipe up
             ref.read(aiBottomSheetStateProvider.notifier).state = 
                 const AiBottomSheetState(isVisible: true, isExpanded: true);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            // A subtle gradient border at the top
            border: Border(
              top: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Pull Handle & Header
              _buildDragHandle(context, ref, state, isDark),
              
              // Chat Content Viewer
              Expanded(
                child: ClipRRect(
                   // Ensure inner content doesn't overflow the rounded corners at the top
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                  child: AiChatScreen(
                    site: site,
                    isFromBrowser: true,
                    showHeader: false, // We pass a new flag to hide the default full-screen header
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context, WidgetRef ref, AiBottomSheetState state, bool isDark) {
    return GestureDetector(
      onTap: () {
         // Toggle expanded state
         ref.read(aiBottomSheetStateProvider.notifier).state = AiBottomSheetState(
           isVisible: true, 
           isExpanded: !state.isExpanded,
         );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             // Empty space to balance
            const SizedBox(width: 32),
            
            // Drag Indicator Pill
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Close button
            GestureDetector(
              onTap: () {
                ref.read(aiBottomSheetStateProvider.notifier).state = const AiBottomSheetState(isVisible: false);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
