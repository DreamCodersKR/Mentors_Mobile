import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryIcon(
      {super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: const Color(0xFFB794F4),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
