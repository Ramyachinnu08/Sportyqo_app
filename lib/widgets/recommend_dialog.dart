import 'package:flutter/material.dart';

/// Asks the coach for an optional note and star rating before
/// sending a recommendation. Returns null if cancelled.
Future<({String note, double? rating})?> showRecommendDialog(
    BuildContext context, String playerName) {
  final noteCtrl = TextEditingController();
  double? rating;
  return showDialog<({String note, double? rating})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Recommend $playerName',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating',
                style:
                    TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final v = (i + 1).toDouble();
                final filled = (rating ?? 0) >= v;
                return GestureDetector(
                  onTap: () => setState(
                      () => rating = rating == v ? null : v),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: filled
                            ? Colors.amber
                            : Colors.white24,
                        size: 28),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            const Text('Note (optional)',
                style:
                    TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'e.g. Excellent technique and a great team player',
                hintStyle: const TextStyle(
                    color: Colors.white24, fontSize: 12),
                counterStyle:
                    const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context,
                (note: noteCtrl.text.trim(), rating: rating)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Recommend',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
