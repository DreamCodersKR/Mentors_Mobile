import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class MatchProfileSection extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const MatchProfileSection({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger();

    final status = mentorship['status'];
    logger.i('mentorship의 status: $status');

    if (status == 'matched') {
      return MatchedProfile(mentorship: mentorship);
    }

    return UnmatchedProfile(mentorship: mentorship);
  }
}

class MatchedProfile extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const MatchedProfile({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = mentorship['user_nickname'] ?? '알 수 없음';
    final profileUrl = mentorship['profile_photo'];

    final role = mentorship['position'] == 'mentor' ? '멘토' : '멘티';

    return ProfileRow(
      nickname: nickname,
      profileUrl: profileUrl,
      role: role,
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
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
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
