import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      selectedItemColor: const Color(0xFFB794F4),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "게시판"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "채팅방"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "내정보"),
      ],
    );
  }
}
