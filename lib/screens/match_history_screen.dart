import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
// import 'package:mentors_app/services/mentorship_service.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final Logger logger = Logger();
  // final MentorshipService _mentorshipService = MentorshipService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          '매칭기록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('mentorships')
                    .where('userId', isEqualTo: user.uid)
                    .where('isDeleted', isEqualTo: false)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final mentorships = snapshot.data?.docs ?? [];
                  if (mentorships.isEmpty) {
                    return const Center(child: Text('매칭 기록이 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: mentorships.length,
                    itemBuilder: (context, index) {
                      final mentorship =
                          mentorships[index].data() as Map<String, dynamic>;
                      return _buildMentorshipCard(mentorship);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text('프로필',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: Text('닉네임',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.start),
        ),
        Expanded(
          child: Text('역할',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.start),
        ),
        Expanded(
          child: Text('카테고리',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left),
        ),
        Expanded(
          child: Text('상태',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildMentorshipCard(Map<String, dynamic> mentorship) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showMentorshipDetails(mentorship),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildProfileSection(mentorship),
              ),
              Expanded(
                child: Text(
                  mentorship['categoryName'] ?? '카테고리 없음',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildStatusIcon(mentorship['status']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> mentorship) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(mentorship['userId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final nickname = userData?['user_nickname'] ?? '알 수 없음';
        final profileUrl = userData?['profile_photo'];
        final role = mentorship['position'] == 'mentor' ? '멘토' : '멘티';

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  profileUrl != null ? NetworkImage(profileUrl) : null,
              child: profileUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nickname,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                role,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, color: Colors.orange),
            Text('대기중', style: TextStyle(fontSize: 12, color: Colors.orange))
          ],
        );
      case 'matched':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            Text('매칭완료', style: TextStyle(fontSize: 12, color: Colors.green))
          ],
        );
      case 'failed':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.red),
            Text('매칭실패', style: TextStyle(fontSize: 12, color: Colors.red))
          ],
        );
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  void _showMentorshipDetails(Map<String, dynamic> mentorship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mentorship['categoryName']} 매칭 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('역할: ${mentorship['position']}'),
              Text('상태: ${mentorship['status']}'),
              Text('생성일: ${_formatTimestamp(mentorship['createdAt'])}'),
              const Divider(),
              const Text('답변 내용:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  List<Widget> _buildAnswersList(Map<String, dynamic> mentorship) {
    final answers = mentorship['answers'] as List?;
    if (answers == null || answers.isEmpty) {
      return [const Text('답변 정보가 없습니다.')];
    }

    return answers.asMap().entries.map((entry) {
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
