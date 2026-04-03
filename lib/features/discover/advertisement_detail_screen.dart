import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/advertisement.dart';
import '../../l10n/app_localizations.dart';

class AdvertisementDetailScreen extends ConsumerStatefulWidget {
  final Advertisement advertisement;

  const AdvertisementDetailScreen({super.key, required this.advertisement});

  @override
  ConsumerState<AdvertisementDetailScreen> createState() =>
      _AdvertisementDetailScreenState();
}

class _AdvertisementDetailScreenState
    extends ConsumerState<AdvertisementDetailScreen> {
  late final QuillController _quillController;
  late final Document _doc;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.advertisement.detailCardInstructions != null &&
          widget.advertisement.detailCardInstructions!.isNotEmpty) {
        final decoded = jsonDecode(
          widget.advertisement.detailCardInstructions!,
        );
        _doc = Document.fromJson(decoded);
      } else {
        _doc = Document();
      }
    } catch (_) {
      _doc = Document()
        ..insert(0, widget.advertisement.detailCardInstructions ?? '');
    }

    _quillController = QuillController(
      document: _doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void _handleDetailCardAction() {
    final ad = widget.advertisement;
    switch (ad.detailCardActionType) {
      case 'external_link':
        if (ad.detailCardActionUrl != null &&
            ad.detailCardActionUrl!.isNotEmpty) {
          final uri = Uri.tryParse(ad.detailCardActionUrl!);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case 'whatsapp':
        if (ad.detailCardActionUrl != null &&
            ad.detailCardActionUrl!.isNotEmpty) {
          String url = ad.detailCardActionUrl!;
          if (!url.startsWith('http')) {
            url = url.replaceAll('+', '').replaceAll(' ', '');
            url = 'https://wa.me/$url';
          }
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case 'telegram':
        if (ad.detailCardActionUrl != null &&
            ad.detailCardActionUrl!.isNotEmpty) {
          String url = ad.detailCardActionUrl!;
          if (!url.startsWith('http')) {
            url = url.replaceAll('@', '');
            url = 'https://t.me/$url';
          }
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case 'support_chat':
      default:
        // Navigate to in-app support chat
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        GoRouter.of(rootContext).push('/chat');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final ad = widget.advertisement;

    final buttonText =
        (ad.detailCardButtonText != null && ad.detailCardButtonText!.isNotEmpty)
        ? ad.detailCardButtonText!
        : l10n.adDetailDefaultButton;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ad.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBg(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? AppTheme.darkBg : AppTheme.lightBg,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad.textContent != null && ad.textContent!.isNotEmpty)
                    Text(
                      ad.textContent!,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1),

                  const SizedBox(height: 24),

                  // Quill Editor for Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black87,
                      ),
                      child: QuillEditor.basic(
                        controller: _quillController,
                        config: const QuillEditorConfig(
                          showCursor: false,
                          scrollable: false,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(
                    height: 120,
                  ), // Padding for the floating button
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              _handleDetailCardAction();
            },
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: ad.detailCardActionType == 'whatsapp'
                      ? const Color(0xFF25D366)
                      : ad.detailCardActionType == 'telegram'
                      ? const Color(0xFF0088CC)
                      : ad.detailCardActionType == 'external_link'
                      ? Colors.grey[800]
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor:
                      (ad.detailCardActionType == 'whatsapp'
                              ? const Color(0xFF25D366)
                              : ad.detailCardActionType == 'telegram'
                              ? const Color(0xFF0088CC)
                              : ad.detailCardActionType == 'external_link'
                              ? Colors.grey[800]!
                              : AppTheme.primaryColor)
                          .withValues(alpha: 0.4),
                ).copyWith(
                  backgroundColor: ad.detailCardActionType == 'support_chat'
                      ? null
                      : null,
                  backgroundBuilder: ad.detailCardActionType == 'support_chat'
                      ? (ctx, states, child) => Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                const Color(0xFF7C4DFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: child,
                        )
                      : null,
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ad.detailCardActionType == 'whatsapp'
                      ? Icons.chat
                      : ad.detailCardActionType == 'telegram'
                      ? Icons.send
                      : ad.detailCardActionType == 'external_link'
                      ? Icons.open_in_browser
                      : Icons.support_agent_rounded,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign,
          size: 64,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
