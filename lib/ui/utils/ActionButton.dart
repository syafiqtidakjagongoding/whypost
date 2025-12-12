
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const ActionButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Colors.grey[700];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 20, color: buttonColor)],
        ),
      ),
    );
  }
}
