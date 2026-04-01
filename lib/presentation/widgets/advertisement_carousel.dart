import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_theme.dart';

import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../domain/models/advertisement.dart';
import '../../presentation/providers/advertisements_provider.dart';
import '../../l10n/app_localizations.dart';
import 'website_details_dialog.dart';

class AdvertisementCarousel extends ConsumerStatefulWidget {
  final String targetScreen; // 'home' or 'discover'
  final EdgeInsetsGeometry padding;

  const AdvertisementCarousel({
    super.key,
    required this.targetScreen,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  ConsumerState<AdvertisementCarousel> createState() =>
      _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends ConsumerState<AdvertisementCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;
  List<Advertisement> _ads = [];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_ads.isEmpty) return;

    final currentAd = _ads[_currentIndex];
    final duration = Duration(seconds: currentAd.displayDurationSeconds);

    _timer = Timer(duration, () {
      if (!mounted) return;

      if (_currentIndex < _ads.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      _startTimer(); // Schedule the next rotation based on the NEW ad's duration
    });
  }

  String _getRemainingTimeString(BuildContext context, DateTime endDate) {
    final diff = endDate.difference(DateTime.now());
    final l10n = AppLocalizations.of(context)!;

    if (diff.isNegative) return l10n.adEnded;

    if (diff.inDays > 1) {
      return l10n.adEndsInDays(diff.inDays);
    } else if (diff.inDays == 1) {
      return l10n.adEndsInOneDay;
    } else if (diff.inHours > 0) {
      return l10n.adEndsInHours(diff.inHours);
    } else {
      return l10n.adEndsSoon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(advertisementsProvider(widget.targetScreen));

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink(); // Collapses perfectly

        // Reset timer if list changes
        if (_ads.length != ads.length ||
            (_ads.isNotEmpty && _ads.first.id != ads.first.id)) {
          _ads = ads;
          _currentIndex = 0;
          _startTimer();
        }

        return Padding(
          padding: widget.padding,
          child:
              SizedBox(
                    height: 160,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                            _startTimer(); // Reset duration timer upon manual swipe
                          },
                          itemCount: ads.length,
                          itemBuilder: (context, index) {
                            final ad = ads[index];
                            return _buildAdCard(ad);
                          },
                        ),
                        // Dot Indicators
                        if (ads.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(ads.length, (index) {
                                final isActive = index == _currentIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 6,
                                  width: isActive ? 16 : 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, curve: Curves.easeOutQuad),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) =>
          const SizedBox.shrink(), // Fail silently in UI
    );
  }

  void _showDetailCardSheet(Advertisement ad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final buttonText =
        (ad.detailCardButtonText != null && ad.detailCardButtonText!.isNotEmpty)
        ? ad.detailCardButtonText!
        : l10n.adDetailDefaultButton;

    Document doc;
    try {
      if (ad.detailCardInstructions != null &&
          ad.detailCardInstructions!.isNotEmpty) {
        final decoded = jsonDecode(ad.detailCardInstructions!);
        doc = Document.fromJson(decoded);
      } else {
        doc = Document();
      }
    } catch (_) {
      doc = Document()..insert(0, ad.detailCardInstructions ?? '');
    }

    final quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Ad Image Hero ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 180,
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 180,
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
              ),
              // ── Instructions ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black87,
                    ),
                    child: QuillEditor.basic(
                      controller: quillController,
                      config: const QuillEditorConfig(
                        showCursor: false,
                        scrollable: false,
                      ),
                    ),
                  ),
                ),
              ),
              // ── Action Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleDetailCardAction(ad);
                    },
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: ad.detailCardActionType == 'whatsapp'
                              ? const Color(0xFF25D366)
                              : ad.detailCardActionType == 'telegram'
                              ? const Color(0xFF0088CC)
                              : ad.detailCardActionType == 'external_link'
                              ? Colors.grey[800]
                              : null,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor:
                              (ad.detailCardActionType == 'whatsapp'
                                      ? const Color(0xFF25D366)
                                      : ad.detailCardActionType == 'telegram'
                                      ? const Color(0xFF0088CC)
                                      : ad.detailCardActionType ==
                                            'external_link'
                                      ? Colors.grey[800]!
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.4),
                        ).copyWith(
                          backgroundColor:
                              ad.detailCardActionType == 'support_chat'
                              ? null
                              : null,
                          backgroundBuilder:
                              ad.detailCardActionType == 'support_chat'
                              ? (ctx, states, child) => Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        const Color(0xFF7C4DFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
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
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  void _handleDetailCardAction(Advertisement ad) {
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
          // if formatting not as link
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

  Widget _buildAdCard(Advertisement ad) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 4.0,
      ), // Spacing between cards during swipe
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () async {
          // ── Detail Card ──
          if (ad.detailCardEnabled) {
            _showDetailCardSheet(ad);
            return;
          }
          if (ad.linkedWebsiteId != null && ad.linkedWebsiteId!.isNotEmpty) {
            try {
              // Fetch website model to pass format required by routing
              final response = await SupabaseConfig.client
                  .from('websites')
                  .select()
                  .eq('id', ad.linkedWebsiteId!)
                  .maybeSingle();

              if (response != null && mounted) {
                final site = WebsiteModel.fromJson(response);
                // Use root navigator context to ensure dialog can still show safely
                final rootContext = Navigator.of(
                  context,
                  rootNavigator: true,
                ).context;
                GoRouter.of(rootContext).go('/discover');

                await Future.delayed(const Duration(milliseconds: 300));
                if (rootContext.mounted) {
                  showDialog(
                    context: rootContext,
                    builder: (ctx) => WebsiteDetailsDialog(site: site),
                  );
                }
              }
            } catch (e) {
              // Fail silently or log
            }
          } else if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty) {
            final uri = Uri.tryParse(ad.linkUrl!);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: ad.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
            ),

            // Dark Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 0.6, 1.0],
                ),
              ),
            ),

            // Remaining Time Badge (Top Right)
            if (ad.showRemainingTime && ad.adEndDate != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRemainingTimeString(context, ad.adEndDate!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
              ),

            // Bottom Text Content
            if (ad.textContent != null && ad.textContent!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  ad.textContent!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
              ),

            // Progress bar (optional elegant element instead of the timer if they wanted a timer bar)
            // We can add a tiny micro-animation bar at the very bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProgressBar(durationSeconds: ad.displayDurationSeconds),
            ),
          ],
        ),
      ),
    );
  }
}

// A beautiful, subtle progress bar that sweeps across the bottom
class _ProgressBar extends StatefulWidget {
  final int durationSeconds;

  const _ProgressBar({required this.durationSeconds});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _controller.duration = Duration(seconds: widget.durationSeconds);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 3,
            width: MediaQuery.of(context).size.width * _controller.value,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}
