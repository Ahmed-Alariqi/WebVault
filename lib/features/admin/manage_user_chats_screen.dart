import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../presentation/providers/admin_providers.dart';

class ManageUserChatsScreen extends ConsumerWidget {
  const ManageUserChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(adminConversationsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('User Messages'),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(child: Text('No active conversations found.'));
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final hasUnread = conv.unreadAdminCount > 0;

              return Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(
                    conversationProfileProvider(conv.userId),
                  );
                  final allUsersAsync = ref.watch(adminUsersProvider);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Dismissible(
                      key: Key(conv.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(PhosphorIcons.trash(), color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: const Text(
                                "Are you sure you wish to delete this conversation?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("CANCEL"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    "DELETE",
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          try {
                            await deleteConversation(conv.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Conversation deleted'),
                                ),
                              );
                            }
                            ref.invalidate(adminConversationsStreamProvider);
                            return true;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete: $e')),
                              );
                            }
                            return false;
                          }
                        }
                        return false;
                      },
                      onDismissed: (direction) {},
                      child: InkWell(
                        onTap: () {
                          context.push('/admin/chats/${conv.id}');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: hasUnread
                                ? Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1.5,
                                  )
                                : Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                child: profileAsync.when(
                                  data: (p) {
                                    if (p?['avatar_url'] != null) {
                                      return ClipOval(
                                        child: Image.network(
                                          p!['avatar_url'],
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return Text(
                                      (p?['full_name'] ?? '?')
                                          .toString()
                                          .toUpperCase()[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        fontSize: 20,
                                      ),
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                  error: (e, trace) => const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: profileAsync.when(
                                            data: (p) {
                                              return Text(
                                                p?['full_name'] ??
                                                    'Unknown User',
                                                style: TextStyle(
                                                  fontWeight: hasUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                            loading: () =>
                                                const Text('Loading...'),
                                            error: (e, trace) =>
                                                const Text('Error'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat.jm().format(
                                            conv.lastMessageAt,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasUnread
                                                ? AppTheme.primaryColor
                                                : (isDark
                                                      ? Colors.white54
                                                      : Colors.black54),
                                            fontWeight: hasUnread
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Builder(
                                      builder: (context) {
                                        String? email;
                                        if (allUsersAsync.hasValue) {
                                          final users = allUsersAsync.value!;
                                          final u = users
                                              .cast<Map<String, dynamic>?>()
                                              .firstWhere(
                                                (u) => u?['id'] == conv.userId,
                                                orElse: () => null,
                                              );
                                          email = u?['email'];
                                        }

                                        if (email != null) {
                                          return Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conv.lastMessage ??
                                                'Started a conversation',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: hasUnread
                                                  ? (isDark
                                                        ? Colors.white
                                                        : Colors.black87)
                                                  : (isDark
                                                        ? Colors.white70
                                                        : Colors.black54),
                                              fontWeight: hasUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        if (hasUnread) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${conv.unreadAdminCount} New',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
