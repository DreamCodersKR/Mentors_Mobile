import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MatchDetailDialog extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const MatchDetailDialog({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${mentorship['category_name']} 매칭 정보'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('역할: ${mentorship['position'] == 'mentor' ? '멘토' : '멘티'}'),
            Text(
              '상태: ${_getStatusText(mentorship['status'])}',
            ),
            Text('생성일: ${_formatTimestamp(mentorship['created_at'])}'),
            const Divider(),
            const Text(
              '답변 내용:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._buildAnswersList(mentorship),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'matched':
        return '매칭완료';
      case 'failed':
        return '매칭실패';
      default:
        return '알 수 없음';
    }
  }

  List<Widget> _buildAnswersList(Map<String, dynamic> mentorship) {
    final answers = mentorship['answers'] as List?;
    if (answers == null || answers.isEmpty) {
      return [const Text('답변 정보가 없습니다.')];
    }

    return answers.asMap().entries.map<Widget>((entry) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text('답변 ${entry.key + 1}: ${entry.value}'),
      );
    }).toList();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '날짜 정보 없음';
    return timestamp.toDate().toString();
  }
}
