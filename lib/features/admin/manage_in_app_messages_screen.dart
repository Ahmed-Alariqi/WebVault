import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';

class ManageInAppMessagesScreen extends ConsumerStatefulWidget {
  const ManageInAppMessagesScreen({super.key});

  @override
  ConsumerState<ManageInAppMessagesScreen> createState() =>
      _ManageInAppMessagesScreenState();
}

class _ManageInAppMessagesScreenState
    extends ConsumerState<ManageInAppMessagesScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _actionUrlCtrl = TextEditingController();
  final _actionTextCtrl = TextEditingController();
  final _targetVersionCtrl = TextEditingController();
  // 0 = Standard (Shows once), 1 = Recurring (Shows every time), 2 = Hard Block (Not dismissible)
  int _campaignMode = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _imageUrlCtrl.dispose();
    _actionUrlCtrl.dispose();
    _actionTextCtrl.dispose();
    _targetVersionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createMessage() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Message are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await adminCreateInAppMessage({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'image_url': _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        'action_url': _actionUrlCtrl.text.trim().isEmpty
            ? null
            : _actionUrlCtrl.text.trim(),
        'action_text': _actionTextCtrl.text.trim().isEmpty
            ? null
            : _actionTextCtrl.text.trim(),
        'is_dismissible': _campaignMode != 2,
        'show_every_time': _campaignMode != 0,
        'target_version':
            (_campaignMode == 2 && _targetVersionCtrl.text.trim().isNotEmpty)
            ? _targetVersionCtrl.text.trim()
            : null,
        'is_active': false, // created inactive by default
      });

      _titleCtrl.clear();
      _messageCtrl.clear();
      _imageUrlCtrl.clear();
      _actionUrlCtrl.clear();
      _actionTextCtrl.clear();
      _targetVersionCtrl.clear();
      setState(() => _campaignMode = 0);
      ref.invalidate(adminInAppMessagesProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign Created')));
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isOffline =
            errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('connection refused') ||
            errStr.contains('clientexception') ||
            errStr.contains('network is unreachable');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'You are offline. Please check your internet connection.'
                  : 'Failed: $e',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await adminToggleInAppMessage(id, !currentStatus);
      ref.invalidate(adminInAppMessagesProvider);
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isOffline =
            errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('connection refused') ||
            errStr.contains('clientexception') ||
            errStr.contains('network is unreachable');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'You are offline. Please check your internet connection.'
                  : 'Failed to update status: $e',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminDeleteInAppMessage(id);
        ref.invalidate(adminInAppMessagesProvider);
      } catch (e) {
        if (mounted) {
          final errStr = e.toString().toLowerCase();
          final isOffline =
              errStr.contains('socketexception') ||
              errStr.contains('failed host lookup') ||
              errStr.contains('connection refused') ||
              errStr.contains('clientexception') ||
              errStr.contains('network is unreachable');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOffline
                    ? 'You are offline. Please check your internet connection.'
                    : 'Delete failed: $e',
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(adminInAppMessagesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('In-App Messages'),
        forceMaterialTransparency: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Build Form
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'New Campaign',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_titleCtrl, 'Title', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _messageCtrl,
                      'Message',
                      isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _imageUrlCtrl,
                      'Image URL (optional)',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _actionUrlCtrl,
                      'Button URL (optional)',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _actionTextCtrl,
                      'Button Text (optional)',
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Campaign Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.looks_one_outlined),
                          label: Text('Standard'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.repeat),
                          label: Text('Recurring'),
                        ),
                        ButtonSegment(
                          value: 2,
                          icon: Icon(Icons.block),
                          label: Text('Hard Block'),
                        ),
                      ],
                      selected: {_campaignMode},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _campaignMode = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              );
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _campaignMode == 0
                          ? 'Shows once per user. They can dismiss it forever.'
                          : _campaignMode == 1
                          ? 'Shows every time the user opens the app, but they can dismiss it.'
                          : 'Shows every time, CANNOT be dismissed. Blocks the app completely.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_campaignMode == 2) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        _targetVersionCtrl,
                        'Target Version Required (e.g. 1.0.5) (optional)',
                        isDark,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Campaign',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: const Text(
                'EXISTING CAMPAIGNS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Message List
          messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No campaigns yet.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final msg = messages[index];
                  final isActive = msg['is_active'] == true;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isActive)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (msg['is_dismissible'] == false)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        msg['target_version'] != null
                                            ? 'UPDATE: ${msg['target_version']}'
                                            : 'HARD BLOCK',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (msg['show_every_time'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'RECURRING',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      msg['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['message'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Switch(
                              value: isActive,
                              activeThumbColor: AppTheme.primaryColor,
                              onChanged: (val) =>
                                  _toggleStatus(msg['id'], isActive),
                            ),
                            IconButton(
                              icon: Icon(
                                PhosphorIcons.trash(),
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              onPressed: () => _deleteMessage(msg['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
                }, childCount: messages.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverToBoxAdapter(child: OfflineWarningWidget(error: e)),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
