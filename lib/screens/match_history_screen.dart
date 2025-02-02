import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/main.dart';
import 'package:mentors_app/widgets/banner_ad.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.deepPurple[200],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tabs: const [
            Tab(text: '대기'),
            Tab(text: '완료'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 대기 탭
                _buildPendingList(user.uid),
                // 완료 탭
                _buildCompletedList(user.uid),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const BannerAdWidget(),
          const SizedBox(height: 20),
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

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                final modifiedMentorship = {
                  ...mentorship,
                  'user_nickname': userData?['user_nickname'] ?? '알 수 없음',
                  'profile_photo': userData?['profile_photo'] ?? '',
                };

                return MatchHistoryCard(mentorship: modifiedMentorship);
              },
            );
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
        logger.i('스냅샷 체크 : ${mentorships.length}');
        if (mentorships.isEmpty) {
          return const Center(child: Text('완료된 매칭 기록이 없습니다.'));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getMatchedMentorships(mentorships),
          builder: (context, matchedSnapshot) {
            if (matchedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 데이터가 로드된 후에만 로그 출력
            if (matchedSnapshot.hasData) {
              logger.i('매치된 스냅샷 정보: ${matchedSnapshot.data}');
            } else {
              logger.i('매치된 스냅샷 정보: null');
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
      logger.i('_getMatchedMentorships 로 넘어온 멘토쉽 정보 : $mentorshipData');
      final userPosition = mentorshipData['position'] as String?;
      logger.i('_getMatchedMentorships 로 넘어온 유저 position 정보 : $userPosition');
      logger.i('_getMatchedMentorships 로 넘어온 멘토쉽 id 정보 : ${mentorship.id}');

      try {
        QuerySnapshot matchQuery;
        if (userPosition == 'mentor') {
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

          logger.i('matches 쿼리 결과 : $matchData');

          final oppositeRequestId = userPosition == 'mentor'
              ? matchData['menteeRequest_id'] as String
              : matchData['mentorRequest_id'] as String;

          final oppositeUserId = userPosition == 'mentor'
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
            final oppositeMentorshipData = oppositeMentorship.data()!;

            logger.i('상대 유저 정보 : $userData');
            logger.i('상대 멘토쉽 정보 : ${oppositeMentorshipData['answers']}');

            matchedList.add({
              ...oppositeMentorshipData,
              'user_nickname': userData['user_nickname'] ?? '알 수 없음',
              'profile_photo': userData['profile_photo'] ?? '',
              'id': oppositeMentorship.id,
            });
          }
        }
        _logger.i('매칭된 멘토쉽 정보 : ${matchedList[0]['answers']}');
        _logger.i('상대방 매칭 닉네임 : ${matchedList[0]['user_nickname']}');
        _logger.i('상대방 매칭 사진주소 : ${matchedList[0]['profile_photo']}');
        _logger.i('상대방 멘토쉽 상태 : ${matchedList[0]['status']}');
      } catch (e) {
        _logger.e('매칭 정보 조회 중 오류: $e');
      }
    }

    return matchedList;
  }
}
