import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InquiryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> inquiry;

  const InquiryDetailScreen({super.key, required this.inquiry});

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '날짜 정보 없음';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return timestamp.toString();
    }
    return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final subject = inquiry['subject'] ?? '제목 없음';
    final message = inquiry['message'] ?? '문의 내용이 없습니다.';
    final createdAt = _formatTimestamp(inquiry['createdAt']);
    final status = inquiry['status'] == 'pending' ? '답변 대기 중' : '답변 완료';
    final response = inquiry['response'] ?? '';
    final respondedAt = _formatTimestamp(inquiry['respondedAt']);

    return Scaffold(
      backgroundColor: Colors.white, // 연한 보라색 배경
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE2D4FF),
        title: Text(
          '문의 상세',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(subject, status, createdAt),
            SizedBox(height: 20),
            _buildSection('문의 내용', message, Icons.question_answer),
            SizedBox(height: 20),
            _buildSection('답변', response.isEmpty ? '아직 답변이 없습니다.' : response,
                Icons.chat_bubble_outline,
                subtext: response.isEmpty ? '' : '답변 일시: $respondedAt'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String subject, String status, String createdAt) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: TextStyle(fontSize: 24, color: Colors.black),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _buildChip(status),
              SizedBox(width: 10),
              Icon(Icons.access_time, size: 16, color: Color(0xFF9575CD)),
              SizedBox(width: 4),
              Text(
                createdAt,
                style: TextStyle(fontSize: 14, color: Color(0xFF9575CD)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon,
      {String subtext = ''}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB794F4).withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF9575CD)),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          if (subtext.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              subtext,
              style: TextStyle(fontSize: 12, color: Color(0xFF9575CD)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF9575CD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
