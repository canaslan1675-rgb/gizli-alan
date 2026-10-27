import 'package:flutter/material.dart';

/// Joi's round portrait (original AI-generated artwork, see CREDITS.md).
class JoiAvatar extends StatelessWidget {
  const JoiAvatar({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFFF8FD8), width: 1.5),
    ),
    child: ClipOval(
      child: Image.asset(
        size > 96 ? 'assets/joi/joi_512.webp' : 'assets/joi/joi_192.webp',
        key: const ValueKey('joi_avatar'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => Icon(
          Icons.auto_awesome_outlined,
          size: size * 0.55,
          color: const Color(0xFFFF8FD8),
        ),
      ),
    ),
  );
}
