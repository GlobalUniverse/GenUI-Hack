import 'advisor_response.dart';

enum MessageRole { user, advisor }

class ChatMessage {
  final MessageRole role;
  final String text;
  final List<WidgetSpec> widgets;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.widgets = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
