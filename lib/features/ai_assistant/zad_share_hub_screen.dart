import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import 'external_ai_chat_screen.dart';
import 'package:any_link_preview/any_link_preview.dart';

class ZadShareHubScreen extends ConsumerStatefulWidget {
  const ZadShareHubScreen({super.key});

  @override
  ConsumerState<ZadShareHubScreen> createState() => _ZadShareHubScreenState();
}

class _ZadShareHubScreenState extends ConsumerState<ZadShareHubScreen> {
  static const _shareChannel = MethodChannel('com.webvault.app/overlay');
  List<Map<String, dynamic>> _pendingShares = [];
  bool _isLoading = true;
  
  final _labelController = TextEditingController();
  String? _selectedGroupId;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPendingShares();
  }

  Future<void> _loadPendingShares() async {
    try {
      final result = await _shareChannel.invokeMethod('getPendingShares');
      if (result != null) {
        final items = List<Map<dynamic, dynamic>>.from(result as List);
        if (mounted) {
          setState(() {
            _pendingShares = items.map((e) => Map<String, dynamic>.from(e)).toList();
            if (_pendingShares.isNotEmpty) {
              final initialLabel = _pendingShares.first['label'] as String? ?? 'عنصر جديد';
              _labelController.text = initialLabel;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          // Auto close if no shares found
          SystemNavigator.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SystemNavigator.pop();
      }
    }
  }

  Future<void> _saveAllToClipboard() async {
    if (_pendingShares.isEmpty) return;
    final box = Hive.box(kClipboardBox);
    final isSingleShare = _pendingShares.length == 1;
    
    for (int i = 0; i < _pendingShares.length; i++) {
      final args = _pendingShares[i];
      // Use user text for the first item if single, otherwise default label
      final defaultLabel = args['label'] as String? ?? 'Shared item';
      final label = (isSingleShare && i == 0 && _labelController.text.isNotEmpty) ? _labelController.text : defaultLabel;
      final text = args['text'] as String? ?? '';
      
      if (text.isNotEmpty) {
        final id = DateTime.now().microsecondsSinceEpoch.toString() + i.toString();
        final item = {
          'id': id,
          'label': label,
          'value': text,
          'type': 0,
          'isPinned': false,
          'sortOrder': box.length,
          'isEncrypted': false,
          'createdAt': DateTime.now().toIso8601String(),
          'autoDeleteAt': null,
          'groupId': _selectedGroupId,
        };
        await box.put(id, item);
      }
    }
    ref.read(clipboardItemsProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ في زاد المنسوخات بنجاح')),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        SystemNavigator.pop();
      });
    }
  }

  void _askAi(String text) {
    // Navigate to External AI Assistant Screen with the text
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ExternalAiChatScreen(initialText: text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pendingShares.isEmpty) {
      return const SizedBox.shrink(); // Will auto redirect
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstItem = _pendingShares.first;
    final text = firstItem['text'] as String? ?? '';
    final groups = ref.watch(clipboardGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
              ),
            ),
          ),
          
          // Share Hub Dialog
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'تم استقبال مشاركة جديدة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Sneak peek of content
                    if (text.trim().startsWith('http'))
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 90,
                          child: AnyLinkPreview(
                            link: text.trim(),
                            displayDirection: UIDirection.uiDirectionHorizontal,
                            showMultimedia: true,
                            bodyMaxLines: 1,
                            bodyTextOverflow: TextOverflow.ellipsis,
                            titleStyle: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                            bodyStyle: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                            errorWidget: Container(
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: const Center(child: Icon(Icons.link)),
                            ),
                            cache: const Duration(days: 7),
                            backgroundColor: Colors.transparent,
                            borderRadius: 0,
                            removeElevation: true,
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontFamily: 'Cairo',
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Metadata Inputs
                    TextField(
                      controller: _labelController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                      decoration: InputDecoration(
                        labelText: 'تسمية العنصر',
                        labelStyle: TextStyle(fontFamily: 'Cairo', color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (groups.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: InputDecoration(
                          labelText: 'المجموعة (اختياري)',
                          labelStyle: TextStyle(fontFamily: 'Cairo', color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('بدون مجموعة', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                          ...groups.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name, style: const TextStyle(fontFamily: 'Cairo')),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedGroupId = val;
                          });
                        },
                      ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveAllToClipboard,
                            icon: Icon(PhosphorIcons.downloadSimple(), size: 20),
                            label: const Text('حفظ في زاد', style: TextStyle(fontFamily: 'Cairo')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _askAi(text),
                            icon: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), size: 20),
                            label: const Text('اسأل مرشد زاد', style: TextStyle(fontFamily: 'Cairo')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
