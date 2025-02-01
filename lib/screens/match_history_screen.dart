import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/widgets/match_history/match_history_card.dart';
import 'package:mentors_app/widgets/match_history/match_history_header.dart';
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
            const MatchHistoryHeader(),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('mentorships')
                    .where('user_id', isEqualTo: user.uid)
                    .where('is_deleted', isEqualTo: false)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('에러가 발생했습니다: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final mentorships = snapshot.data?.docs ?? [];
                  if (mentorships.isEmpty) {
                    return const Center(
                      child: Text('매칭 기록이 없습니다.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: mentorships.length,
                    itemBuilder: (context, index) {
                      final mentorship =
                          mentorships[index].data() as Map<String, dynamic>;
                      return MatchHistoryCard(mentorship: mentorship);
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
}
