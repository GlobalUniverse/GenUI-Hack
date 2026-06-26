import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/financial_snapshot.dart';
import 'api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ChatMessage> messages = [];
  bool isLoading = false;
  FinancialSnapshot? snapshot;
  String _profileId = 'alex';

  String get profileId => _profileId;

  ChatProvider();

  Future<void> loadProfile(String profileId) async {
    _profileId = profileId;
    messages.clear();
    snapshot = null;
    notifyListeners();
    snapshot = await _api.getSnapshot(profileId: profileId);
    notifyListeners();
  }

  Future<void> refreshSnapshot() async {
    snapshot = null;
    notifyListeners();
    snapshot = await _api.getSnapshot(profileId: _profileId);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    messages.add(ChatMessage(role: MessageRole.user, text: text));
    isLoading = true;
    notifyListeners();

    final history = messages
        .map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.text,
        })
        .toList();

    final response = await _api.askAdvisor(text, history, profileId: _profileId);

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
