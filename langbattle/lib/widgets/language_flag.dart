import 'package:flutter/material.dart';

class LanguageFlag extends StatelessWidget {
  final String language;
  final double width;
  final double height;
  final double borderRadius;

  const LanguageFlag({
    super.key,
    required this.language,
    this.width = 44,
    this.height = 32,
    this.borderRadius = 10,
  });

  static const Map<String, String> assets = {
    'english': 'assets/images/england.png',
    'german': 'assets/images/germany.png',
    'french': 'assets/images/france.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = assets[language.toLowerCase()];

    if (asset == null) {
      return _fallbackFlag();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallbackFlag(),
      ),
    );
  }

  Widget _fallbackFlag() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EC),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(
        Icons.language_rounded,
        size: 18,
        color: Color(0xFF755700),
      ),
    );
  }
}
