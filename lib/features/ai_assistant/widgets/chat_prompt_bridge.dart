import 'package:flutter/widgets.dart';

/// Lets nested widgets (typed inside markdown rendered by either
/// `AiChatScreen` or `ZadExpertScreen`) push a prompt back into the active
/// chat input — without needing a hard reference to the (private) screen
/// state classes.
///
/// Each chat screen wraps its body in `ChatPromptBridge` and supplies an
/// `inject(prompt)` callback that fills its own input controller and focuses
/// it. Mermaid widgets, "ask about this" toolbars, etc., look the bridge up
/// via `ChatPromptBridge.of(context)`.
class ChatPromptBridge extends InheritedWidget {
  final void Function(String prompt) inject;

  const ChatPromptBridge({
    super.key,
    required this.inject,
    required super.child,
  });

  static ChatPromptBridge? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ChatPromptBridge>();
  }

  @override
  bool updateShouldNotify(ChatPromptBridge oldWidget) =>
      oldWidget.inject != inject;
}
