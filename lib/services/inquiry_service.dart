import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String inquiriesCollection = "inquiries";

  Future<void> createInquiry({
    required String subject,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("로그인 되어 있지 않습니다.");
    }
    final docRef = _firestore.collection(inquiriesCollection).doc();
    await docRef.set({
      'authorId': user.uid,
      'subject': subject,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'response': '',
      'respondedAt': null,
      'isDeleted': false,
    });
  }

  Stream<QuerySnapshot> getUserInquiries(String userId) {
    return _firestore
        .collection(inquiriesCollection)
        .where('authorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
