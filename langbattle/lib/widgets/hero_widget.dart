import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HeroWidget extends StatelessWidget
{
  const HeroWidget({super.key,
  required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: "hero-image",
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Lottie.asset('assets/lotties/#0101FTUE_04.json')
        ),),
        Text(title, style: TextStyle(
          fontWeight: FontWeight.bold,
           fontSize: 50, color: Colors.white70,
           letterSpacing: 10
        ))
      ],
      );
  }
}