import 'dart:convert';
import 'package:flutter/material.dart';

/// Reusable square avatar widget.
/// Shows the profile picture if [base64Image] is provided,
/// otherwise falls back to coloured initials from [name].
class UserAvatar extends StatelessWidget {
  final String name;
  final String? base64Image;
  final double size;
  final double borderRadius;

  const UserAvatar({
    super.key,
    required this.name,
    this.base64Image,
    this.size = 72,
    this.borderRadius = 12,
  });

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _color(ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _color(colorScheme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: base64Image != null && base64Image!.isNotEmpty
            ? _ImageAvatar(base64Image: base64Image!, fallbackColor: color, initials: _initials())
            : _InitialsAvatar(color: color, initials: _initials(), size: size),
      ),
    );
  }
}

class _ImageAvatar extends StatelessWidget {
  final String base64Image;
  final Color fallbackColor;
  final String initials;

  const _ImageAvatar({
    required this.base64Image,
    required this.fallbackColor,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _InitialsAvatar(color: fallbackColor, initials: initials, size: double.infinity),
      );
    } catch (_) {
      return _InitialsAvatar(color: fallbackColor, initials: initials, size: double.infinity);
    }
  }
}

class _InitialsAvatar extends StatelessWidget {
  final Color color;
  final String initials;
  final double size;

  const _InitialsAvatar({
    required this.color,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size == double.infinity ? 26 : size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}