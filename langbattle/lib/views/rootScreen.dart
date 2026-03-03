import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/welcome_page.dart';
import 'package:langbattle/views/widget_tree.dart';

class RootScreen extends StatefulWidget {
  final BattleService battleService;
  final String? token;
  const RootScreen({super.key, required this.battleService, this.token});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool? isAuthenticated; 

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    widget.battleService.stream.listen((event) {
      if (event["type"] == "auth_success") {
        setState(() => isAuthenticated = true);
      }
      if (event["type"] == "auth_failed") {
        setState(() => isAuthenticated = false);
      }
    });
  }

  void _checkAuthStatus() {
  if (widget.token == null || widget.token!.isEmpty) {
    // No token = not authenticated, show welcome immediately
    setState(() => isAuthenticated = false);
  } else {
    // Token exists, wait for WebSocket validation with timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && isAuthenticated == null) {
        setState(() => isAuthenticated = false);
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    // While auth state is being determined, always show a loading screen
    if (isAuthenticated == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return isAuthenticated == true
        ? WidgetTree(battleService: widget.battleService)
        : WelcomePage();
  }
}
