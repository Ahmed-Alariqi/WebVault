import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                    ], // Violet to Blue
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 60,
                        20,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.analyticsLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.analyticsTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.analyticsSubtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: analyticsAsync.when(
              data: (data) => _buildAnalyticsBody(context, data, isDark),
              loading: () => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: OfflineWarningWidget(error: e),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBody(
    BuildContext context,
    AdminAnalyticsData data,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // 1. KPI Cards Grid (2x2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CompactKpiCard(
                      title: AppLocalizations.of(context)!.analyticsTotalUsers,
                      value: data.totalUsers.toString(),
                      subtitle: AppLocalizations.of(
                        context,
                      )!.analyticsActiveThisWeek(data.activeThisWeek),
                      icon: PhosphorIcons.users(),
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompactKpiCard(
                      title: AppLocalizations.of(context)!.analyticsActiveToday,
                      value: data.activeToday.toString(),
                      subtitle: AppLocalizations.of(
                        context,
                      )!.analyticsUniqueLogins,
                      icon: PhosphorIcons.pulse(),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CompactKpiCard(
                      title: AppLocalizations.of(context)!.analyticsItemViews,
                      value: data.totalItemViews.toString(),
                      subtitle: AppLocalizations.of(
                        context,
                      )!.analyticsTotalAcrossItems,
                      icon: PhosphorIcons.eye(),
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompactKpiCard(
                      title: AppLocalizations.of(context)!.analyticsBookmarks,
                      value: data.totalBookmarks.toString(),
                      subtitle: AppLocalizations.of(
                        context,
                      )!.analyticsSavedByUsers,
                      icon: PhosphorIcons.bookmarkSimple(),
                      color: const Color(0xFFEC4899),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 32),

        // Total Items Header & Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: AppLocalizations.of(context)!.localeName == 'ar'
                    ? 'إحصائيات العناصر'
                    : 'Items Statistics',
                icon: PhosphorIcons.database(PhosphorIconsStyle.fill),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Total Items (Prominent Card)
              _InteractiveStatCard(
                title: AppLocalizations.of(
                  context,
                )!.websitesTitle, // "Websites/Items"
                count: data.totalItems,
                subCategories: data.itemsByCategory, // All sub-categories
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),

              // Content Types Grid
              if (data.itemsByContentType.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.itemsByContentType.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final entry = data.itemsByContentType.entries.elementAt(
                      index,
                    );
                    final type = entry.key;
                    final count = entry.value;
                    final subCats =
                        data.categoryBreakdownByContentType[type] ??
                        <String, int>{};

                    return _InteractiveStatCard(
                      title: _typeDisplayName(context, type),
                      count: count,
                      subCategories: subCats,
                      icon: _typeIcon(type),
                      color: _typeColor(type),
                      isDark: isDark,
                      isFullWidth: false,
                    );
                  },
                ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 32),

        // 2. DAU Chart (Daily Active Users)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: AppLocalizations.of(context)!.analyticsDau,
            icon: PhosphorIcons.trendUp(),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: _buildDauChart(context, data.dauData, isDark),
          ).animate().fadeIn().slideY(begin: 0.1),
        ),

        const SizedBox(height: 32),

        // 3. Popular Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: AppLocalizations.of(context)!.analyticsTopViewed,
            icon: PhosphorIcons.trophy(),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topViewedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(AppLocalizations.of(context)!.analyticsNoViewData),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: data.topViewedItems.length,
              itemBuilder: (context, index) {
                final item = data.topViewedItems[index];
                return _TopItemCard(
                  item: item,
                  rank: index + 1,
                  metricLabel: AppLocalizations.of(context)!.analyticsViews(
                    item['views'] is num ? (item['views'] as num).toInt() : 0,
                  ),
                  isDark: isDark,
                );
              },
            ),
          ).animate().fadeIn(),

        const SizedBox(height: 32),

        // 4. Most Bookmarked Items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: AppLocalizations.of(context)!.analyticsMostBookmarked,
            icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topBookmarkedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(AppLocalizations.of(context)!.analyticsNoBookmarkData),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: data.topBookmarkedItems.length,
              itemBuilder: (context, index) {
                final item = data.topBookmarkedItems[index];
                return _TopItemCard(
                  item: item,
                  rank: index + 1,
                  metricLabel: AppLocalizations.of(context)!.analyticsSaves(
                    item['bookmarks'] is num
                        ? (item['bookmarks'] as num).toInt()
                        : 0,
                  ),
                  isDark: isDark,
                );
              },
            ),
          ).animate().fadeIn(),

        const SizedBox(height: 32),

        // 5. Top Researched Items (15 Days)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: AppLocalizations.of(context)!.analyticsTopSearches,
            icon: PhosphorIcons.magnifyingGlass(),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(AppLocalizations.of(context)!.analyticsNoSearchData),
          )
        else
          _TopSearchesList(
            searches: data.topSearches,
            isDark: isDark,
          ).animate().fadeIn(),

        const SizedBox(height: 60),
      ],
    );
  }

  String _typeDisplayName(BuildContext context, String type) {
    switch (type) {
      case 'prompt':
        return AppLocalizations.of(context)!.badgePrompt;
      case 'offer':
        return AppLocalizations.of(context)!.badgeOffer;
      case 'news':
      case 'announcement':
        return AppLocalizations.of(context)!.newsBadge;
      case 'tutorial':
        return AppLocalizations.of(context)!.badgeTutorial;
      case 'tool':
        return AppLocalizations.of(context)!.toolBadge;
      case 'course':
      case 'courses':
        return AppLocalizations.of(context)!.courseBadge;
      default:
        return AppLocalizations.of(context)!.badgeWebsite;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'prompt':
        return PhosphorIcons.sparkle();
      case 'offer':
        return PhosphorIcons.tag();
      case 'news':
      case 'announcement':
        return PhosphorIcons.megaphone();
      case 'tutorial':
        return PhosphorIcons.chalkboardTeacher();
      case 'tool':
        return PhosphorIcons.wrench();
      case 'course':
      case 'courses':
        return PhosphorIcons.graduationCap();
      default:
        return PhosphorIcons.globe();
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'prompt':
        return const Color(0xFF9C27B0);
      case 'offer':
        return const Color(0xFFFF9800);
      case 'news':
      case 'announcement':
        return const Color(0xFF2196F3);
      case 'tutorial':
        return const Color(0xFFE91E63);
      case 'tool':
        return const Color(0xFF607D8B);
      case 'course':
      case 'courses':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildDauChart(
    BuildContext context,
    List<Map<String, dynamic>> dauData,
    bool isDark,
  ) {
    if (dauData.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.analyticsNotEnoughData),
      );
    }

    final spots = <FlSpot>[];
    double maxCount = 0;

    for (int i = 0; i < dauData.length; i++) {
      final count = (dauData[i]['count'] as num).toDouble();
      if (count > maxCount) maxCount = count;
      spots.add(FlSpot(i.toDouble(), count));
    }

    // Ensure chart has some vertical space even with low numbers
    if (maxCount < 5) maxCount = 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dauData.length > 7
                  ? (dauData.length / 5).floorToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dauData.length) {
                  final date = DateTime.parse(dauData[value.toInt()]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxCount > 10 ? (maxCount / 5).floorToDouble() : 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dauData.length - 1).toDouble(),
        minY: 0,
        maxY: maxCount + (maxCount * 0.2), // Add 20% padding at top
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _CompactKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _TopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int rank;
  final String metricLabel;
  final bool isDark;

  const _TopItemCard({
    required this.item,
    required this.rank,
    required this.metricLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String;
    final imageUrl = item['image_url'] as String?;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: imageUrl != null
                    ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metricLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchCard extends StatelessWidget {
  final String query;
  final int count;
  final int rank;
  final bool isDark;

  const _TopSearchCard({
    required this.query,
    required this.count,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                '"$query"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.users(),
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count searches',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchesList extends StatefulWidget {
  final List<Map<String, dynamic>> searches;
  final bool isDark;

  const _TopSearchesList({required this.searches, required this.isDark});

  @override
  State<_TopSearchesList> createState() => _TopSearchesListState();
}

class _TopSearchesListState extends State<_TopSearchesList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayCount = _showAll
        ? widget.searches.length
        : (widget.searches.length > 5 ? 5 : widget.searches.length);

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final search = widget.searches[index];
              return _TopSearchCard(
                query: search['query'] ?? 'Unknown',
                count: search['search_count'] is num
                    ? (search['search_count'] as num).toInt()
                    : 0,
                rank: index + 1,
                isDark: widget.isDark,
              );
            },
          ),
        ),
        if (widget.searches.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                });
              },
              icon: Icon(
                _showAll ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
              ),
              label: Text(
                _showAll
                    ? AppLocalizations.of(context)!.analyticsShowLess
                    : AppLocalizations.of(
                        context,
                      )!.analyticsViewAll(widget.searches.length),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _InteractiveStatCard extends StatelessWidget {
  final String title;
  final int count;
  final Map<String, int> subCategories;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isFullWidth;

  const _InteractiveStatCard({
    required this.title,
    required this.count,
    required this.subCategories,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isFullWidth = false,
  });

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '$count ${AppLocalizations.of(context)!.websitesTitle}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.categoriesTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                if (subCategories.isEmpty)
                  Text(
                    'No Sub-categories',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: subCategories.entries.map((e) {
                      return _StatChip(
                        label: e.key,
                        value: e.value.toString(),
                        color: color,
                        icon: PhosphorIcons.tag(),
                        isDark: isDark,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showBreakdown(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isFullWidth
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: isDark ? 0.3 : 0.8),
                    color.withValues(alpha: isDark ? 0.6 : 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isFullWidth
              ? null
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFullWidth
                ? Colors.transparent
                : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isFullWidth
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 36,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.localeName == 'ar'
                                ? 'المزيد'
                                : 'More',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            PhosphorIcons.caretDown(),
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
            : Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      PhosphorIcons.caretCircleDoubleDown(),
                      size: 16,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
