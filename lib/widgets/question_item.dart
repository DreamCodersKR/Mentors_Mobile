import 'package:flutter/material.dart';

class QuestionItem extends StatelessWidget {
  final String questionTitle; // 질문의 제목
  final String hintText; // 입력 필드 힌트
  final int maxLength; // 최대 글자 수
  final int maxLines; // 최대 줄 수
  final TextEditingController controller; // 입력값을 저장하는 컨트롤러

  const QuestionItem({
    super.key,
    required this.questionTitle,
    required this.hintText,
    required this.maxLength,
    required this.maxLines,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionTitle,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLength: maxLength,
          maxLines: maxLines,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
      ],
    );
  }
}
