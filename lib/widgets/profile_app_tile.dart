import 'package:flutter/material.dart';

import '../services/second_phone_service.dart';
import '../theme.dart';

/// Launcher-style tile for an app that lives in the second phone (work
/// profile). The icon comes from Android with the work badge already drawn.
class ProfileAppTile extends StatelessWidget {
  const ProfileAppTile({super.key, required this.app, required this.onTap});

  final ProfileApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = app.icon;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: icon != null
                ? Image.memory(icon, gaplessPlayback: true)
                : const Icon(Icons.apps, size: 40),
          ),
          const SizedBox(height: 6),
          Text(
            app.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: GizliTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
