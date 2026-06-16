import 'dart:convert';

import 'package:flutter/material.dart';

/// Avatar de usuario que entiende tres orígenes:
/// - data URI en base64 (imagen subida por el usuario, guardada en el backend),
/// - URL http(s),
/// - o, si no hay nada, un avatar generado con la inicial del nombre.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 24,
  });

  final String name;
  final String? url;
  final double radius;

  ImageProvider? _imageProvider() {
    final u = (url ?? '').trim();
    try {
      if (u.startsWith('data:image')) {
        final base64Part = u.substring(u.indexOf(',') + 1);
        return MemoryImage(base64Decode(base64Part));
      }
      if (u.startsWith('http')) return NetworkImage(u);
    } catch (_) {
      // data URI corrupto → cae al avatar con inicial.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider();
    final inicial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    if (provider != null) {
      return CircleAvatar(radius: radius, backgroundImage: provider);
    }
    // Sin imagen: círculo con la inicial.
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withAlpha(60),
      child: Text(
        inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
