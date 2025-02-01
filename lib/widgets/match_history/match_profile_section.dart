import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchProfileSection extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const MatchProfileSection({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final status = mentorship['status'];
    final mentorshipId = mentorship['id'];

    if (status == 'matched') {
      return _buildMatchedProfileSection(mentorshipId, currentUserId);
    }

    return _buildUnmatchedProfileSection();
  }

  Widget _buildMatchedProfileSection(
      String? mentorshipId, String? currentUserId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'success')
          .where('is_deleted', isEqualTo: false)
          .where('menteeRequest_id', isEqualTo: mentorshipId)
          .get(),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var matchDocs = matchSnapshot.data!.docs;

        if (matchDocs.isEmpty) {
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('matches')
                .where('status', isEqualTo: 'success')
                .where('is_deleted', isEqualTo: false)
                .where('mentorRequest_id', isEqualTo: mentorshipId)
                .get(),
            builder: (context, mentorMatchSnapshot) {
              if (!mentorMatchSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              matchDocs = mentorMatchSnapshot.data!.docs;
              if (matchDocs.isEmpty) {
                return const Center(child: Text('매칭 정보를 찾을 수 없습니다'));
              }

              return MatchedProfile(
                match: matchDocs.first.data() as Map<String, dynamic>,
                currentUserId: currentUserId,
              );
            },
          );
        }

        return MatchedProfile(
          match: matchDocs.first.data() as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
      },
    );
  }

  Widget _buildUnmatchedProfileSection() {
    return UnmatchedProfile(mentorship: mentorship);
  }
}

class MatchedProfile extends StatelessWidget {
  final Map<String, dynamic> match;
  final String? currentUserId;

  const MatchedProfile({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = match['mentee_id'] == currentUserId
        ? match['mentor_id']
        : match['mentee_id'];

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final nickname = userData?['user_nickname'] ?? '알 수 없음';
        final profileUrl = userData?['profile_photo'];
        final role = match['mentee_id'] == currentUserId ? '멘토' : '멘티';

        return ProfileRow(
          nickname: nickname,
          profileUrl: profileUrl,
          role: role,
        );
      },
    );
  }
}

class UnmatchedProfile extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const UnmatchedProfile({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(mentorship['user_id'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final nickname = userData?['user_nickname'] ?? '알 수 없음';
        final profileUrl = userData?['profile_photo'];
        final role = mentorship['position'] == 'mentor' ? '멘토' : '멘티';

        return ProfileRow(
          nickname: nickname,
          profileUrl: profileUrl,
          role: role,
        );
      },
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String nickname;
  final String? profileUrl;
  final String role;

  const ProfileRow({
    super.key,
    required this.nickname,
    required this.profileUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: profileUrl != null && profileUrl!.isNotEmpty
              ? NetworkImage(profileUrl!)
              : null,
          child: profileUrl == null || profileUrl!.isEmpty
              ? const Icon(Icons.person)
              : null,
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
  }
}
