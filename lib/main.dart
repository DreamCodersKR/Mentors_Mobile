import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/firebase_options.dart';
import 'package:mentors_app/screens/board_screen.dart';
import 'package:mentors_app/screens/chat_list_screen.dart';
import 'package:mentors_app/screens/chat_room_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/main_screen.dart';
import 'package:mentors_app/screens/my_boards_screen.dart';
import 'package:mentors_app/screens/my_info_screen.dart';
import 'package:mentors_app/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize().then((status) {
    logger.i("Google Mobile Ads 초기화 상태: ${status.adapterStatuses}");
  }).catchError((e) {
    logger.e("Google Mobile Ads 초기화 실패: $e");
  });
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    logger.e('알람 권한 거부됨');
  }

  FirebaseMessagingHandler.initialize();

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i("백그라운드 메시지 수신: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mentors',
      theme: ThemeData(
        primaryColor: const Color(0xFFB794F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB794F4),
          primary: const Color(0xFFB794F4),
          secondary: const Color(0xFF9575CD),
        ),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
        '/board': (context) => const BoardScreen(),
        '/login': (context) => const LoginScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/myInfo': (context) => const MyInfoScreen(),
        '/myBoards': (context) => const MyBoardsScreen(),
        '/chat_room': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is Map<String, dynamic>) {
            return ChatRoomScreen(
              chatRoomId: arguments['chatRoomId'] as String? ?? '',
              userName: arguments['userName'] as String? ?? '알 수 없음',
              userId: arguments['userId'] as String? ?? '',
            );
          }

          // 만약 arguments가 잘못된 경우, 안전한 기본값을 제공
          return const ChatListScreen();
        },
      },
    );
  }
}

class FirebaseMessagingHandler {
  static void initialize() {
    // 앱 실행 중 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i("포그라운드 메시지 수신: ${message.notification?.title}");
      if (message.notification != null) {
        _showSnackbar(
          message.notification?.title ?? "알림",
          message.notification?.body ?? "내용 없음",
        );
      }
      if (message.data.isNotEmpty) {
        logger.i("메시지 데이터: ${message.data}");
      }
    });

    // 앱이 백그라운드 상태일 때 메시지를 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final action = message.data['action'];
      if (action != null && action is Map<String, dynamic>) {
        final screen = action['screen'];
        if (screen != null) {
          navigatorKey.currentState?.pushNamed(screen, arguments: action);
        }
      }
      logger.i('알림 클릭 후 앱 열림 : ${message.notification?.title}');
    });

    // 앱 초기 실행 시 알림 데이터 처리
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final action = message.data['action'];
        if (action != null && action is Map<String, dynamic>) {
          final screen = action['screen'];
          if (screen != null) {
            navigatorKey.currentState
                ?.pushNamed(screen, arguments: message.data);
          }
        }
      }
    });

    // 토큰 갱신 처리
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      logger.i("새로운 FCM 토큰: $newToken");

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          await userDocRef.update({
            'fcm_tokens': FieldValue.arrayUnion([newToken]),
            'updated_at': FieldValue.serverTimestamp(),
          });
          logger.i("Firestore에 새로운 FCM 토큰이 저장되었습니다.");
        } else {
          logger.e("Firestore에서 사용자 문서를 찾을 수 없습니다.");
        }
      } else {
        logger.w("사용자가 로그인되어 있지 않아 FCM 토큰 업데이트를 건너뜁니다.");
      }
    });

    // 현재 토큰 가져오기
    FirebaseMessaging.instance.getToken().then((token) {
      logger.i("현재 FCM 토큰: $token");
    });
  }

  static void _showSnackbar(String title, String body) {
    final context = navigatorKey.currentState?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title\n$body")),
      );
    }
  }
}
