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
                            child: const Text(
                              'ANALYTICS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'App Activities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Monitor user engagement and content performance',
                            style: TextStyle(
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

        // 1. KPI Cards Row (Horizontal Scroll)
        SizedBox(
          height: 160,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              _KpiCard(
                title: 'Total Users',
                value: data.totalUsers.toString(),
                subtitle: '${data.activeThisWeek} active this week',
                icon: PhosphorIcons.users(),
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                title: 'Active Today',
                value: data.activeToday.toString(),
                subtitle: 'Unique logins / opens',
                icon: PhosphorIcons.pulse(),
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                title: 'Item Views',
                value: data.totalItemViews.toString(),
                subtitle: 'Total across all items',
                icon: PhosphorIcons.eye(),
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                title: 'Bookmarks',
                value: data.totalBookmarks.toString(),
                subtitle: 'Saved by users',
                icon: PhosphorIcons.bookmarkSimple(),
                color: const Color(0xFFEC4899),
                isDark: isDark,
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: 0.1),

        const SizedBox(height: 32),

        // 2. DAU Chart (Daily Active Users)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: 'Daily Active Users (15 Days)',
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
            child: _buildDauChart(data.dauData, isDark),
          ).animate().fadeIn().slideY(begin: 0.1),
        ),

        const SizedBox(height: 32),

        // 3. Popular Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: 'Top Viewed Items',
            icon: PhosphorIcons.trophy(),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topViewedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No view data available yet.'),
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
                  metricLabel: '${item['views']} views',
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
            title: 'Most Bookmarked',
            icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topBookmarkedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No bookmark data available yet.'),
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
                  metricLabel: '${item['bookmarks']} saves',
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
            title: 'Top Searches (15 Days)',
            icon: PhosphorIcons.magnifyingGlass(),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        if (data.topSearches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No search data available yet.'),
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

  Widget _buildDauChart(List<Map<String, dynamic>> dauData, bool isDark) {
    if (dauData.isEmpty) {
      return const Center(child: Text('Not enough data to generate chart'));
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

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _KpiCard({
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
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black45,
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
                _showAll ? 'Show Less' : 'View All (${widget.searches.length})',
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
