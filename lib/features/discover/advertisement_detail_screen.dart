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
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Image with sleek gradient
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'ad_image_${ad.id}',
                        child: Image.network(
                          ad.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBg(),
                        ),
                      ),
                      // Premium sleek dual-gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              isDark ? AppTheme.darkBg : AppTheme.lightBg,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (ad.textContent != null && ad.textContent!.isNotEmpty)
                        Text(
                              ad.textContent!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutQuart),

                      const SizedBox(height: 32),

                      // Instructions Card (Flutter Quill)
                      if (_doc.toPlainText().trim().isNotEmpty) ...[
                        Text(
                          l10n.adDetailInstructions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                        const SizedBox(height: 16),
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.black87,
                                ),
                                child: QuillEditor.basic(
                                  controller: _quillController,
                                  config: const QuillEditorConfig(
                                    showCursor: false,
                                    scrollable: false,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    isDark ? AppTheme.darkBg : AppTheme.lightBg,
                    (isDark ? AppTheme.darkBg : AppTheme.lightBg).withValues(
                      alpha: 0.9,
                    ),
                    (isDark ? AppTheme.darkBg : AppTheme.lightBg).withValues(
                      alpha: 0.0,
                    ),
                  ],
                  stops: const [0.2, 0.7, 1.0],
                ),
              ),
              child: _buildActionButton(ad, buttonText)
                  .animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Advertisement ad, String buttonText) {
    Color baseColor;
    IconData iconData;

    switch (ad.detailCardActionType) {
      case 'whatsapp':
        baseColor = const Color(0xFF25D366);
        iconData = Icons.chat;
        break;
      case 'telegram':
        baseColor = const Color(0xFF0088CC);
        iconData = Icons.send;
        break;
      case 'external_link':
        baseColor = Colors.grey[800]!;
        iconData = Icons.open_in_browser;
        break;
      case 'support_chat':
      default:
        baseColor = AppTheme.primaryColor;
        iconData = Icons.support_agent_rounded;
        break;
    }

    final isSupport = ad.detailCardActionType == 'support_chat';

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: isSupport
            ? LinearGradient(
                colors: [AppTheme.primaryColor, const Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: ElevatedButton(
        onPressed: _handleDetailCardAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSupport ? Colors.transparent : baseColor,
          foregroundColor: Colors.white,
          shadowColor: Colors
              .transparent, // Disable native shadow to use container shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 24),
              const SizedBox(width: 12),
              Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
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
