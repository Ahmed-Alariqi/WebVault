import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Navigate to the new detail screen using GoRouter
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    GoRouter.of(rootContext).push('/advertisement-detail', extra: ad);
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
