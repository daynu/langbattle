import "package:flutter/material.dart";
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/home_page.dart';
import 'package:langbattle/views/pages/settings_page.dart';
class WidgetTree extends StatelessWidget {
  final BattleService battleService;
  const WidgetTree({super.key, required this.battleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomePage(battleService: battleService),
    );
  }
}