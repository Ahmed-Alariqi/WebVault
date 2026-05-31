import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../presentation/providers/admin_providers.dart';

class CloudControlCenterScreen extends StatefulWidget {
  const CloudControlCenterScreen({super.key});

  @override
  State<CloudControlCenterScreen> createState() => _CloudControlCenterScreenState();
}

class _CloudControlCenterScreenState extends State<CloudControlCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Media Tab State
  List<Map<String, dynamic>> _files = [];
  bool _isLoadingMedia = true;
  String? _selectedFolder; // null means 'All'
  String _selectedFileType = 'all'; // 'all', 'image', 'non-image'
  String _tableSearchQuery = ''; // Filter tables in quotas tab

  // Uploading state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadType = 'صورة'; // 'صورة' or 'فيديو'

  final List<Map<String, String?>> _folders = [
    {'name': 'الكل', 'path': null},
    {'name': 'المستكشف', 'path': '/discover'},
    {'name': 'المعرض', 'path': '/discover/gallery'},
    {'name': 'الإعلانات', 'path': '/advertisements'},
    {'name': 'الإشعارات', 'path': '/notifications'},
    {'name': 'المجموعات', 'path': '/collections'},
    {'name': 'الفيديوهات', 'path': '/discover/videos'},
  ];

  final TextEditingController _tableSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _tableSearchController.addListener(() {
      if (mounted) {
        setState(() {
          _tableSearchQuery = _tableSearchController.text;
        });
      }
    });
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMedia = true;
    });

    try {
      final results = await ImageKitService.listFiles(
        folder: _selectedFolder,
        fileType: _selectedFileType,
      );
      if (mounted) {
        setState(() {
          _files = results;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
        AdminUIUtils.showError(context, 'فشل جلب الملفات: $e');
      }
    }
  }

  Future<void> _deleteMedia(Map<String, dynamic> file) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileId = file['fileId'] as String?;
    final name = file['name'] as String? ?? '';

    if (fileId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text(
              'تأكيد الحذف النهائي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الملف نهائياً من حساب ImageKit السحابي؟\n\n$name',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoadingMedia = true);

      final success = await ImageKitService.deleteFile(fileId);

      if (mounted) {
        if (success) {
          AdminUIUtils.showSuccess(context, 'تم حذف الملف بنجاح!');
          _loadMedia();
        } else {
          setState(() => _isLoadingMedia = false);
          AdminUIUtils.showError(context, 'فشل حذف الملف.');
        }
      }
    }
  }

  Future<void> _startUploadFlow() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'نوع الملف المراد رفعه',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'image'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(PhosphorIcons.image(PhosphorIconsStyle.fill), color: AppTheme.primaryColor, size: 36),
                          const SizedBox(height: 8),
                          const Text('رفع صورة', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'video'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(PhosphorIcons.videoCamera(PhosphorIconsStyle.fill), color: Colors.purple, size: 36),
                          const SizedBox(height: 8),
                          const Text('رفع فيديو', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (type == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadType = type == 'image' ? 'صورة' : 'فيديو';
    });

    final targetFolder = _selectedFolder ?? '/discover';

    try {
      String? url;
      if (type == 'image') {
        url = await ImageKitService.pickAndUpload(
          folder: targetFolder,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      } else {
        url = await ImageKitService.pickAndUploadVideo(
          folder: targetFolder,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }

      if (mounted) {
        setState(() => _isUploading = false);
        if (url != null) {
          AdminUIUtils.showSuccess(context, 'تم رفع الـ $_uploadType بنجاح!');
          _loadMedia();
        } else {
          AdminUIUtils.showWarning(context, 'تم إلغاء عملية الرفع.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        AdminUIUtils.showError(context, 'فشل عملية الرفع: $e');
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewVideo(String url) {
    showDialog(
      context: context,
      builder: (ctx) => _VideoPreviewDialog(videoUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'مركز التحكم والخدمات السحابية',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'إدارة الوسائط 📁', icon: Icon(PhosphorIcons.folderOpen(), size: 20)),
            Tab(text: 'النسخ الاحتياطي ☁️', icon: Icon(PhosphorIcons.cloudArrowUp(), size: 20)),
            Tab(text: 'حصص الكوتا 📊', icon: Icon(PhosphorIcons.chartBar(), size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Media Manager
          _buildMediaTab(isDark),

          // TAB 2: Backup and Sync (Coming soon)
          _buildPlaceholderTab(
            isDark,
            icon: PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.thin),
            title: 'المزامنة والنسخ الاحتياطي السحابي',
            description: 'ستتمكن قريباً من ربط حساب Google Drive الخاص بك لعمل نسخ احتياطي تلقائي وسحابي لكافة البيانات المحلية وقاعدة بيانات التطبيق بشكل آمن ومجدول.',
          ),

          // TAB 3: Usage and Quotas
          _buildQuotasTab(isDark),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _startUploadFlow,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(PhosphorIcons.uploadSimple()),
              label: const Text('رفع ملف سحابي', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildMediaTab(bool isDark) {
    return Column(
      children: [
        // Uploading indicator if active
        if (_isUploading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جاري رفع الـ $_uploadType سحابياً...',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(_uploadProgress * 100).toInt()}%'),
              ],
            ),
          ),

        // Folder Filtering Scroll View
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _folders.map((folder) {
              final isSelected = _selectedFolder == folder['path'];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: Text(folder['name']!),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFolder = folder['path'];
                      });
                      _loadMedia();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // FileType Segment Filtering
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('نوع الملف:  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFileTypeButton('الكل', 'all', isDark),
                      const SizedBox(width: 8),
                      _buildFileTypeButton('صور فقط 🖼️', 'image', isDark),
                      const SizedBox(width: 8),
                      _buildFileTypeButton('فيديوهات فقط 🎥', 'non-image', isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 24),

        // Files List Grid View
        Expanded(
          child: _isLoadingMedia
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.folderOpen(PhosphorIconsStyle.thin),
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          const Text('لا توجد ملفات مرفوعة في هذا المجلد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('اضغط على الزر بالأسفل لرفع صورة أو فيديو جديد سحابياً', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        final url = file['url'] as String? ?? '';
                        final name = file['name'] as String? ?? '';
                        final size = file['size'] as int? ?? 0;
                        final isVideo = file['fileType'] == 'non-image' || url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Visual thumbnail / placeholder
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: isVideo
                                      ? Container(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                PhosphorIcons.videoCamera(PhosphorIconsStyle.duotone),
                                                size: 40,
                                                color: Colors.purple.withValues(alpha: 0.7),
                                              ),
                                              Positioned(
                                                bottom: 8,
                                                left: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('فيديو', style: TextStyle(color: Colors.white, fontSize: 10)),
                                                ),
                                              ),
                                              // Play Button Overlay
                                              CircleAvatar(
                                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                                child: IconButton(
                                                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                  onPressed: () => _previewVideo(url),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: ImageKitService.thumbnail(url),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => const Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                            ),
                                            // Clickable cover for zoom preview
                                            Positioned.fill(
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _previewImage(url),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              // Description & actions
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatBytes(size),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                        Row(
                                          children: [
                                            // Copy link button
                                            IconButton(
                                              icon: Icon(PhosphorIcons.copy(), size: 14),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(26, 26),
                                              ),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: url));
                                                AdminUIUtils.showSuccess(context, 'تم نسخ رابط الملف بنجاح!');
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            // Delete button
                                            IconButton(
                                              icon: Icon(PhosphorIcons.trash(), size: 14, color: Colors.redAccent),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(26, 26),
                                              ),
                                              onPressed: () => _deleteMedia(file),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: (index * 20).ms).fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95));
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFileTypeButton(String label, String value, bool isDark) {
    final isSelected = _selectedFileType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFileType = value;
        });
        _loadMedia();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotasTab(bool isDark) {
    // Media calculation
    int totalMediaSize = 0;
    for (final f in _files) {
      totalMediaSize += (f['size'] as num? ?? 0).toInt();
    }
    final double totalMediaSizeMb = totalMediaSize / (1024 * 1024);
    final double imageKitPercent = (totalMediaSize / (20.0 * 1024 * 1024 * 1024)).clamp(0.0, 1.0); // 20 GB free tier

    return Consumer(
      builder: (context, ref, child) {
        final usageAsync = ref.watch(supabaseDatabaseUsageProvider);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(supabaseDatabaseUsageProvider);
            await _loadMedia();
          },
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and intro
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'حصص الاستهلاك والكوتا سحابياً',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'مراقبة فورية لحدود استهلاك باقات السحابة المجانية لـ Supabase و ImageKit وتفاصيل الجداول.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Grid cards for main services
                usageAsync.when(
                  data: (usage) {
                    final totalDbBytes = usage['total_db_bytes'] as num? ?? 0;
                    const limitBytes = 500 * 1024 * 1024; // 500 MB
                    final percent = (totalDbBytes / limitBytes).clamp(0.0, 1.0);
                    final remainingBytes = limitBytes - totalDbBytes;
                    final remainingMb = remainingBytes / (1024 * 1024);

                    return Column(
                      children: [
                        Row(
                          children: [
                            // Card 1: Supabase DB
                            Expanded(
                              child: _buildQuotaCard(
                                isDark: isDark,
                                icon: PhosphorIcons.database(PhosphorIconsStyle.bold),
                                title: 'قاعدة بيانات Supabase',
                                currentUsage: usage['total_db_pretty'] as String? ?? '0 B',
                                limit: '500 MB',
                                percent: percent,
                                subtitle: 'المتبقي: ${remainingMb.toStringAsFixed(1)} MB',
                                progressColor: percent > 0.8 
                                    ? Colors.redAccent 
                                    : (percent > 0.5 ? Colors.orangeAccent : Colors.tealAccent),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Card 2: ImageKit
                            Expanded(
                              child: _buildQuotaCard(
                                isDark: isDark,
                                icon: PhosphorIcons.image(PhosphorIconsStyle.bold),
                                title: 'وسائط ImageKit',
                                currentUsage: '${totalMediaSizeMb.toStringAsFixed(2)} MB',
                                limit: '20 GB',
                                percent: imageKitPercent,
                                subtitle: 'عدد الملفات: ${_files.length}',
                                progressColor: imageKitPercent > 0.8 
                                    ? Colors.redAccent 
                                    : (imageKitPercent > 0.5 ? Colors.orangeAccent : Colors.lightBlueAccent),
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(height: 24),

                        // Public Tables size breakdown card
                        _buildTablesBreakdownCard(isDark, usage),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                          SizedBox(height: 12),
                          Text('جاري تحميل بيانات الكوتا الفورية...'),
                        ],
                      ),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text('فشل تحميل الكوتا: $err'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(supabaseDatabaseUsageProvider);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuotaCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String currentUsage,
    required String limit,
    required double percent,
    required String subtitle,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentUsage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                '/ $limit',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTablesBreakdownCard(bool isDark, Map<String, dynamic> usage) {
    final tables = List<Map<String, dynamic>>.from(
      (usage['tables'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    // Sort by size_bytes descending
    tables.sort((a, b) {
      final aSize = a['size_bytes'] as num? ?? 0;
      final bSize = b['size_bytes'] as num? ?? 0;
      return bSize.compareTo(aSize);
    });

    final filteredTables = tables.where((t) {
      final name = (t['table_name'] as String? ?? '').toLowerCase();
      return name.contains(_tableSearchQuery.toLowerCase());
    }).toList();

    final totalPublicBytes = usage['public_tables_bytes'] as num? ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.funnel(PhosphorIconsStyle.bold), color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'حجم وجداول قاعدة البيانات (Breakdown)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'الإجمالي: ${usage['public_tables_pretty'] ?? '0 B'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _tableSearchController,
            decoration: InputDecoration(
              hintText: 'البحث عن جدول...',
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
              suffixIcon: _tableSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _tableSearchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (filteredTables.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('لا توجد جداول مطابقة للبحث.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTables.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white12 : Colors.black12,
                height: 24,
              ),
              itemBuilder: (context, index) {
                final table = filteredTables[index];
                final String name = table['table_name'] as String? ?? '—';
                final String totalSizePretty = table['total_size'] as String? ?? '0 B';
                final int sizeBytes = (table['size_bytes'] as num? ?? 0).toInt();
                final int rowCount = (table['row_count'] as num? ?? 0).toInt();
                
                final double relativePercent = (sizeBytes / totalPublicBytes).clamp(0.0, 1.0);

                // Highlight tables being cleaned up or that are large
                final bool isLoggingTable = name == 'ai_usage_log' || name == 'user_activity';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                color: isLoggingTable ? AppTheme.primaryColor : null,
                              ),
                            ),
                            if (isLoggingTable) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'تنظيف تلقائي 🧹',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          totalSizePretty,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد الصفوف: $rowCount',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        Text(
                          '${(relativePercent * 100).toStringAsFixed(1)}% من الإجمالي',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: relativePercent,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLoggingTable 
                              ? AppTheme.primaryColor.withValues(alpha: 0.8) 
                              : (isDark ? Colors.white30 : Colors.black26),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            icon,
            size: 100,
            color: isDark ? Colors.white24 : Colors.black12,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'ميزة قيد التطوير مستقبلياً',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

// Custom Dialog to play direct videos using chewie and video_player
class _VideoPreviewDialog extends StatefulWidget {
  final String videoUrl;

  const _VideoPreviewDialog({required this.videoUrl});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted) {
          setState(() => _hasError = true);
        }
      });

      await _videoController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'خطأ في تشغيل الفيديو: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('معاينة الفيديو', style: TextStyle(color: Colors.white)),
          ),
          Container(
            height: size.height * 0.45,
            width: double.infinity,
            alignment: Alignment.center,
            child: _hasError
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'تعذر تحميل الفيديو',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : !_isInitialized
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
          ),
        ],
      ),
    );
  }
}
