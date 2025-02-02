import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/widgets/match_history/match_profile_section.dart';
import 'package:mentors_app/widgets/match_history/match_status_icon.dart';
import 'package:mentors_app/widgets/match_history/match_detail_dialog.dart';

class MatchHistoryCard extends StatelessWidget {
  final Map<String, dynamic> mentorship;
  final Logger logger = Logger();

  MatchHistoryCard({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showMentorshipDetails(context, mentorship),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: MatchProfileSection(mentorship: mentorship),
              ),
              Expanded(
                child: Text(
                  mentorship['category_name'] ?? '카테고리 없음',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: MatchStatusIcon(status: mentorship['status']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMentorshipDetails(
      BuildContext context, Map<String, dynamic> mentorship) {
    logger.i(
        '_showMentorshipDetails 의 mentorship 유저 id : ${mentorship['user_id']}');
    logger.i(
        '_showMentorshipDetails 의 mentorship 닉네임 : ${mentorship['user_nickname']}');
    logger.i(
        '_showMentorshipDetails 의 mentorship 카테고리이름 : ${mentorship['category_name']}');
    logger.i(
        '_showMentorshipDetails 의 mentorship 역할 : ${mentorship['position']}');
    logger
        .i('_showMentorshipDetails 의 mentorship 상태 : ${mentorship['status']}');
    logger
        .i('_showMentorshipDetails 의 mentorship 자체의 id : ${mentorship['id']}');
    showDialog(
      context: context,
      builder: (context) => MatchDetailDialog(mentorship: mentorship),
    );
  }
}
