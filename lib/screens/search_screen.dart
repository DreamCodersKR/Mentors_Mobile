import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/search_result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recentSearchesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches');

      final querySnapshot = await recentSearchesRef
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _recentSearches =
            querySnapshot.docs.map((doc) => doc['query'] as String).toList();
      });
    } catch (e) {
      logger.e('최근 검색어 불러오기 오류: $e');
    }
  }

  Future<void> _saveSearch(String searchQuery) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || searchQuery.isEmpty) return;

    try {
      final recentSearchesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches');

      // 중복 검색어 제거: 동일한 검색어가 있으면 삭제
      final querySnapshot =
          await recentSearchesRef.where('query', isEqualTo: searchQuery).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // 새로운 검색어 추가
      await recentSearchesRef.add({
        'query': searchQuery,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _loadRecentSearches(); // UI 업데이트
    } catch (e) {
      logger.e('검색어 저장 오류: $e');
    }
  }

  Future<void> _clearAllSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recentSearchesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches');

      final querySnapshot = await recentSearchesRef.get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _recentSearches.clear();
      });
    } catch (e) {
      logger.e('검색어 전체 삭제 오류: $e');
    }
  }

  Future<void> _removeSearchItem(String searchItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recentSearchesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches');

      final querySnapshot =
          await recentSearchesRef.where('query', isEqualTo: searchItem).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _recentSearches.remove(searchItem);
      });
    } catch (e) {
      logger.e('검색어 삭제 오류: $e');
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _saveSearch(query);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            searchQuery: query,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "검색",
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "최근 검색",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllSearches,
                  child: const Text(
                    "전체 삭제",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _recentSearches.length,
                itemBuilder: (context, index) {
                  final searchItem = _recentSearches[index];
                  return ListTile(
                    title: Text(searchItem),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeSearchItem(searchItem),
                    ),
                    onTap: () {
                      // TODO: 선택된 검색어로 검색 수행
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
