import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/financial_snapshot.dart';
import 'api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ChatMessage> messages = [];
  bool isLoading = false;
  FinancialSnapshot? snapshot;

  ChatProvider() {
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    snapshot = await _api.getSnapshot();
    notifyListeners();
  }

  Future<void> refreshSnapshot() async {
    snapshot = null;
    notifyListeners();
    snapshot = await _api.getSnapshot();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    messages.add(ChatMessage(role: MessageRole.user, text: text));
    isLoading = true;
    notifyListeners();

    final history = messages
        .where((m) => m.role == MessageRole.user)
        .map((m) => {'role': 'user', 'content': m.text})
        .toList();

    final response = await _api.askAdvisor(text, history);

    messages.add(ChatMessage(
      role: MessageRole.advisor,
      text: response.text,
      widgets: response.widgets,
    ));
    isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    messages.clear();
    notifyListeners();
  }
}
