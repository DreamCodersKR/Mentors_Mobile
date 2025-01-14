import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 광고 SDK 추가

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BannerAd? _bannerAd; // 배너 광고 객체
  bool _isAdLoaded = false; // 광고 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // 배너 광고 로드
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // AdMob 광고 단위 ID (일단 테스트용)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 광고 메모리 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mentors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF0E6FF), // 상단 앱바 배경색
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // 알림 버튼 동작
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.black),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _CategoryIcon(label: "IT/전문기술", icon: Icons.computer),
                  _CategoryIcon(label: "예술", icon: Icons.palette),
                  _CategoryIcon(label: "학업/교육", icon: Icons.menu_book),
                  _CategoryIcon(label: "마케팅", icon: Icons.business),
                  _CategoryIcon(label: "자기개발", icon: Icons.edit),
                  _CategoryIcon(label: "취업&커리어", icon: Icons.work),
                  _CategoryIcon(label: "금융/경제", icon: Icons.monetization_on),
                  _CategoryIcon(label: "기타", icon: Icons.more_horiz),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "자유게시판",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: List.generate(
                  4,
                  (i) => const _BoardItem(
                    title: "Title",
                    category: "스터디 구인",
                    date: "2023-01-01",
                    likes: "추천 : 123",
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 광고 배너 영역
              if (_isAdLoaded)
                Center(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // 네비게이션 바 동작
        },
        selectedItemColor: const Color(0xFFB794F4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "게시판"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "채팅방"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryIcon({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: const Color(0xFFB794F4)),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _BoardItem extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String likes;

  const _BoardItem({
    required this.title,
    required this.category,
    required this.date,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  likes,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
