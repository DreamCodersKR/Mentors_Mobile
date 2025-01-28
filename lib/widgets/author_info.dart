import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorInfo extends StatelessWidget {
  final String authorUid;
  final String author;

  const AuthorInfo({
    super.key,
    required this.authorUid,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authorUid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              );
            }
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final profilePhotoUrl = userData?['profile_photo'] ?? '';

            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey,
              backgroundImage: profilePhotoUrl.isNotEmpty
                  ? NetworkImage(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          author,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
