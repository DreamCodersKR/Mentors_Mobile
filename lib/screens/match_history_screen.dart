import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/main.dart';
import 'package:mentors_app/widgets/match_history/match_history_card.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대기'),
            Tab(text: '완료'),
          ],
          labelColor: Colors.black,
          indicatorColor: Colors.deepPurple,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 대기 탭
          _buildPendingList(user.uid),
          // 완료 탭
          _buildCompletedList(user.uid),
        ],
      ),
    );
  }

  Widget _buildPendingList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentorships')
          .where('user_id', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'failed'])
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
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
          return const Center(child: Text('대기중인 매칭 기록이 없습니다.'));
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
    );
  }

  Widget _buildCompletedList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentorships')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'matched')
          .where('is_deleted', isEqualTo: false)
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
          return const Center(child: Text('완료된 매칭 기록이 없습니다.'));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getMatchedMentorships(mentorships),
          builder: (context, matchedSnapshot) {
            logger.i('매칭된 멘토쉽 정보: ${matchedSnapshot.data}');
            if (matchedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!matchedSnapshot.hasData || matchedSnapshot.data!.isEmpty) {
              return const Center(child: Text('매칭된 기록을 찾을 수 없습니다.'));
            }

            return ListView.builder(
              itemCount: matchedSnapshot.data!.length,
              itemBuilder: (context, index) {
                return MatchHistoryCard(
                  mentorship: matchedSnapshot.data![index],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getMatchedMentorships(
      List<QueryDocumentSnapshot> mentorships) async {
    List<Map<String, dynamic>> matchedList = [];

    for (var mentorship in mentorships) {
      final mentorshipData = mentorship.data() as Map<String, dynamic>;
      final position = mentorshipData['position'] as String?;

      try {
        QuerySnapshot matchQuery;
        if (position == 'mentor') {
          matchQuery = await FirebaseFirestore.instance
              .collection('matches')
              .where('mentorRequest_id', isEqualTo: mentorship.id)
              .where('status', isEqualTo: 'success')
              .where('is_deleted', isEqualTo: false)
              .get();
        } else {
          matchQuery = await FirebaseFirestore.instance
              .collection('matches')
              .where('menteeRequest_id', isEqualTo: mentorship.id)
              .where('status', isEqualTo: 'success')
              .where('is_deleted', isEqualTo: false)
              .get();
        }

        if (matchQuery.docs.isNotEmpty) {
          final matchData =
              matchQuery.docs.first.data() as Map<String, dynamic>;
          final oppositeRequestId = position == 'mentor'
              ? matchData['menteeRequest_id'] as String
              : matchData['mentorRequest_id'] as String;

          final oppositeUserId = position == 'mentor'
              ? matchData['mentee_id'] as String
              : matchData['mentor_id'] as String;

          // 상대방의 mentorship 정보 가져오기
          final oppositeMentorship = await FirebaseFirestore.instance
              .collection('mentorships')
              .doc(oppositeRequestId)
              .get();

          // 상대방의 사용자 정보 가져오기
          final oppositeUser = await FirebaseFirestore.instance
              .collection('users')
              .doc(oppositeUserId)
              .get();

          if (oppositeMentorship.exists && oppositeUser.exists) {
            final userData = oppositeUser.data()!;
            matchedList.add({
              ...oppositeMentorship.data()!,
              'user_nickname': userData['user_nickname'] ?? '알 수 없음',
              'profile_photo': userData['profile_photo'] ?? '',
              'original_position': position,
              'opposite_user_id': oppositeUserId,
            });
          }
        }
        logger.i('상대방 매칭 정보 조회 : $matchedList');
      } catch (e) {
        _logger.e('매칭 정보 조회 중 오류: $e');
      }
    }

    return matchedList;
  }
}
