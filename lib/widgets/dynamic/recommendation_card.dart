import 'package:flutter/material.dart';

class RecommendationCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const RecommendationCard({super.key, required this.data});

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  _Status _status = _Status.idle;

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? 'Recommendation';
    final body = widget.data['body'] as String? ?? '';
    final action = widget.data['action'] as String? ?? 'Accept';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF1E2A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          if (_status == _Status.idle)
            Row(children: [
              _chip(action, Colors.greenAccent, () => setState(() => _status = _Status.accepted)),
              const SizedBox(width: 8),
              _chip('Snooze', Colors.white24, () => setState(() => _status = _Status.snoozed)),
              const SizedBox(width: 8),
              _chip('Dismiss', Colors.white12, () => setState(() => _status = _Status.dismissed)),
            ])
          else
            Text(
              _status == _Status.accepted ? '✓ Accepted' : _status == _Status.snoozed ? '⏰ Snoozed' : '✕ Dismissed',
              style: TextStyle(
                color: _status == _Status.accepted ? Colors.greenAccent : Colors.white38,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

enum _Status { idle, accepted, snoozed, dismissed }
