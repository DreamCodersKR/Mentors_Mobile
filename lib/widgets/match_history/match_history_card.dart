import 'package:flutter/material.dart';
import 'package:mentors_app/widgets/match_history/match_profile_section.dart';
import 'package:mentors_app/widgets/match_history/match_status_icon.dart';
import 'package:mentors_app/widgets/match_history/match_detail_dialog.dart';

class MatchHistoryCard extends StatelessWidget {
  final Map<String, dynamic> mentorship;

  const MatchHistoryCard({
    super.key,
    required this.mentorship,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showMentorshipDetails(context),
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

  void _showMentorshipDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MatchDetailDialog(mentorship: mentorship),
    );
  }
}
