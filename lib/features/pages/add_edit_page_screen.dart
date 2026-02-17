import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/page_model.dart';
import '../../presentation/widgets/modern_form_widgets.dart';

class AddEditPageScreen extends ConsumerStatefulWidget {
  final String? pageId;

  const AddEditPageScreen({super.key, this.pageId});

  @override
  ConsumerState<AddEditPageScreen> createState() => _AddEditPageScreenState();
}

class _AddEditPageScreenState extends ConsumerState<AddEditPageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isFavorite = false;
  bool _isEditing = false;
  PageModel? _existingPage;

  @override
  void initState() {
    super.initState();
    if (widget.pageId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final repo = ref.read(pageRepositoryProvider);
        final page = repo.getById(widget.pageId!);
        if (page != null) {
          _existingPage = page;
          _urlController.text = page.url;
          _titleController.text = page.title;
          _notesController.text = page.notes;
          _tagsController.text = page.tags.join(', ');
          setState(() => _isFavorite = page.isFavorite);
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final page = _isEditing
        ? _existingPage!.copyWith(
            url: _urlController.text.trim(),
            title: _titleController.text.trim(),
            notes: _notesController.text.trim(),
            tags: tags,
            isFavorite: _isFavorite,
          )
        : PageModel(
            id: const Uuid().v4(),
            url: _urlController.text.trim(),
            title: _titleController.text.trim().isEmpty
                ? _urlController.text.trim()
                : _titleController.text.trim(),
            notes: _notesController.text.trim(),
            tags: tags,
            isFavorite: _isFavorite,
            createdAt: DateTime.now(),
          );

    if (_isEditing) {
      ref.read(pagesProvider.notifier).updatePage(page);
    } else {
      ref.read(pagesProvider.notifier).addPage(page);
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
              size: 32,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _isFavorite
                    ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                    : PhosphorIcons.heart(),
                color: _isFavorite ? AppTheme.errorColor : null,
                size: 28,
              ),
              onPressed: () => setState(() => _isFavorite = !_isFavorite),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          children: [
            // Title
            Text(
              _isEditing ? 'Edit Page' : 'New Page',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Identity Section
            ModernFormWidgets.sectionHeader('Identity', isDark: isDark),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              decoration: ModernFormWidgets.inputDecoration(
                context,
                label: 'URL',
                hint: 'https://example.com',
                icon: PhosphorIcons.link(),
                isDark: isDark,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL is required';
                return null;
              },
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              decoration: ModernFormWidgets.inputDecoration(
                context,
                label: 'Title',
                hint: 'My Awesome Page',
                icon: PhosphorIcons.textT(),
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Details Section
            ModernFormWidgets.sectionHeader('Details', isDark: isDark),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              decoration: ModernFormWidgets.inputDecoration(
                context,
                label: 'Notes',
                hint: 'What is this page about?',
                icon: PhosphorIcons.note(),
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            TextFormField(
              controller: _tagsController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              decoration: ModernFormWidgets.inputDecoration(
                context,
                label: 'Tags',
                hint: 'work, research, social',
                icon: PhosphorIcons.tag(),
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 48),

            // Action Button
            ModernFormWidgets.gradientButton(
              label: _isEditing ? 'Update Page' : 'Save Page',
              icon: _isEditing
                  ? PhosphorIcons.checkCircle()
                  : PhosphorIcons.floppyDisk(),
              onPressed: _save,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
