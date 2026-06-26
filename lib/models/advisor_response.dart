class AdvisorResponse {
  final String text;
  final List<WidgetSpec> widgets;

  AdvisorResponse({required this.text, required this.widgets});

  factory AdvisorResponse.fromJson(Map<String, dynamic> json) {
    return AdvisorResponse(
      text: json['text'] ?? '',
      widgets: (json['widgets'] as List<dynamic>? ?? [])
          .map((w) => WidgetSpec.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WidgetSpec {
  final String type;
  final Map<String, dynamic> data;

  WidgetSpec({required this.type, required this.data});

  factory WidgetSpec.fromJson(Map<String, dynamic> json) {
    return WidgetSpec(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
