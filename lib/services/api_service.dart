import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/advisor_response.dart';
import '../models/financial_snapshot.dart';

class ApiService {
  static String get _base => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  // Returns profile_id string on success, null on failure
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<FinancialSnapshot> getSnapshot({String profileId = 'alex'}) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/snapshot?profile_id=$profileId'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return FinancialSnapshot.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return FinancialSnapshot.mock();
  }

  Future<AdvisorResponse> askAdvisor(String question, List<Map<String, String>> history, {String profileId = 'alex'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/advisor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question, 'history': history, 'profile_id': profileId}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return AdvisorResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return _mockAdvisorResponse(question);
  }

  AdvisorResponse _mockAdvisorResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('afford') && q.contains('dinner')) {
      return AdvisorResponse(
        text: "Your checking balance is \$1,284.50. With rent due in 2 days (\$1,500), you're actually a bit short. I'd hold off on dinner out tonight — or keep it under \$30.",
        widgets: [
          WidgetSpec(type: 'summary_card', data: {'label': 'Checking Balance', 'value': 1284.50, 'subtitle': 'Rent due in 2 days'}),
          WidgetSpec(type: 'upcoming_bills', data: {}),
          WidgetSpec(type: 'recommendation_card', data: {
            'title': 'Cook at home tonight',
            'body': 'Save ~\$40 and keep your buffer before rent.',
            'action': 'Set a dinner budget reminder',
          }),
        ],
      );
    } else if (q.contains('overspend') || q.contains('where did')) {
      return AdvisorResponse(
        text: "Dining and rideshare jumped the most this month. Dining is up 18% and rideshare is up 42% compared to last month.",
        widgets: [
          WidgetSpec(type: 'spending_chart', data: {}),
          WidgetSpec(type: 'transaction_table', data: {}),
          WidgetSpec(type: 'recommendation_card', data: {
            'title': 'Cut rideshare by 2 trips/week',
            'body': 'That saves ~\$80/month and puts you back on track.',
            'action': 'Set rideshare budget',
          }),
        ],
      );
    } else if (q.contains('save') || q.contains('1000') || q.contains('goal')) {
      return AdvisorResponse(
        text: "To save \$1,000 in 60 days you need to set aside \$500/month — about \$125/week. Based on your current cash flow, that's tight but doable if you trim dining and rideshare.",
        widgets: [
          WidgetSpec(type: 'goal_progress', data: {'name': 'New Goal', 'target': 1000, 'current': 0, 'days_left': 60}),
          WidgetSpec(type: 'spending_chart', data: {}),
          WidgetSpec(type: 'recommendation_card', data: {
            'title': 'Auto-transfer \$125/week to savings',
            'body': "You'll hit \$1,000 by day 56.",
            'action': 'Set up auto-transfer',
          }),
        ],
      );
    } else {
      return AdvisorResponse(
        text: "Here's a snapshot of your finances. Your checking is at \$1,284.50 and you've spent \$3,180 this month against \$4,200 income.",
        widgets: [
          WidgetSpec(type: 'summary_card', data: {'label': 'Checking', 'value': 1284.50, 'subtitle': 'Available now'}),
          WidgetSpec(type: 'summary_card', data: {'label': 'Monthly Spend', 'value': 3180.0, 'subtitle': 'vs \$4,200 income'}),
          WidgetSpec(type: 'spending_chart', data: {}),
        ],
      );
    }
  }
}
