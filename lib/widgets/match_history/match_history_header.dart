import 'package:flutter/material.dart';

class MatchHistoryHeader extends StatelessWidget {
  const MatchHistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            '프로필',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '닉네임',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
        ),
        Expanded(
          child: Text(
            '역할',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
        ),
        Expanded(
          child: Text(
            '카테고리',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: Text(
            '상태',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
