import 'package:flutter/material.dart';
import '../../main.dart';

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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: AppColors.inkMid, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 14),
          if (_status == _Status.idle)
            Row(children: [
              _chip(action, true, () => setState(() => _status = _Status.accepted)),
              const SizedBox(width: 8),
              _chip('Snooze', false, () => setState(() => _status = _Status.snoozed)),
              const SizedBox(width: 8),
              _chip('Dismiss', false, () => setState(() => _status = _Status.dismissed)),
            ])
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(20)),
              child: Text(
                _status == _Status.accepted ? 'Accepted' : _status == _Status.snoozed ? 'Snoozed' : 'Dismissed',
                style: TextStyle(
                  color: _status == _Status.accepted ? AppColors.green : AppColors.inkMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: primary ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary ? AppColors.ink : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: primary ? Colors.white : AppColors.inkMid, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

enum _Status { idle, accepted, snoozed, dismissed }
