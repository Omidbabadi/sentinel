import 'package:flutter/material.dart';

class ServerStackBadge extends StatelessWidget {
  const new({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Center(child: Icon(Icons.dns_outlined, size: 14, color: color)),
    );
  }
}
