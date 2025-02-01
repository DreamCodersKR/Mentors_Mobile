import 'package:flutter/material.dart';

class MatchStatusIcon extends StatelessWidget {
  final String? status;

  const MatchStatusIcon({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, color: Colors.orange),
            Text(
              '대기중',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            )
          ],
        );
      case 'matched':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            Text(
              '매칭완료',
              style: TextStyle(fontSize: 12, color: Colors.green),
            )
          ],
        );
      case 'failed':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.red),
            Text(
              '매칭실패',
              style: TextStyle(fontSize: 12, color: Colors.red),
            )
          ],
        );
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}
