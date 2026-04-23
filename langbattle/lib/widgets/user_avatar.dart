import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';

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

class _ImageAvatar extends StatefulWidget {
  final String base64Image;
  final Color fallbackColor;
  final String initials;

  const _ImageAvatar({
    required this.base64Image,
    required this.fallbackColor,
    required this.initials,
  });

  @override
  State<_ImageAvatar> createState() => _ImageAvatarState();
}

class _ImageAvatarState extends State<_ImageAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    try {
      _bytes = base64Decode(widget.base64Image);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return _InitialsAvatar(
        color: widget.fallbackColor,
        initials: widget.initials,
        size: double.infinity,
      );
    }
    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _InitialsAvatar(
        color: widget.fallbackColor,
        initials: widget.initials,
        size: double.infinity,
      ),
    );
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