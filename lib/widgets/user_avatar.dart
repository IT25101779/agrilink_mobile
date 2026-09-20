import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/profile_api.dart';
import '../theme/app_theme.dart';

/// A person's profile picture, or their initial when they have none.
class UserAvatar extends StatelessWidget {
  final String? userId;
  final String name;
  final double size;
  final bool hasPicture;
  final String version; // changes when the picture changes, so the cache refreshes

  const UserAvatar({super.key, required this.userId, required this.name, this.size = 44, this.hasPicture = true, this.version = ""});

  Widget _initial() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.forestLight, shape: BoxShape.circle),
        child: Text(name.trim().isEmpty ? "?" : name.trim().substring(0, 1).toUpperCase(), style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: AppColors.forest)),
      );

  @override
  Widget build(BuildContext context) {
    if (userId == null || !hasPicture) return _initial();
    return FutureBuilder<Uint8List?>(
      future: ProfileApi.avatarBytes(userId!, version: version),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return _initial();
        return ClipOval(child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true));
      },
    );
  }
}
