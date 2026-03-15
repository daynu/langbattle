
import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/onboarding-language-page.dart';
import 'package:langbattle/widgets/hero_widget.dart'; 
import 'package:langbattle/views/pages/login_page.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  final BattleService battleService = BattleService()..connect();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HeroWidget(title: ""),
            FittedBox(
              child: Text(
                "LangBattle",
                style: TextStyle(
                  fontSize: 50,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(battleService: battleService),
                  ),
                );
              },
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Log in"),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OnboardingLanguagePage(battleService: battleService),
                  ),
                );
              },
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
