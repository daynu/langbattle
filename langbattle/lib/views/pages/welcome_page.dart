import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/onboarding-language-page.dart';
import 'package:langbattle/views/pages/login_page.dart';
import 'package:lottie/lottie.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  final BattleService battleService = BattleService()..connect();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 384,
                        minHeight: constraints.maxHeight - 64,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              SizedBox(
                                width: 132,
                                height: 132,
                                child: Hero(
                                  tag: "hero-image",
                                  child: Lottie.asset(
                                    'assets/lotties/#0101FTUE_04.json',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const FittedBox(
                                child: Text(
                                  "LangBattle",
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 48,
                                    height: 1.05,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1C19),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 72),
                          Column(
                            children: [
                              _WelcomeActionButton(
                                label: "Log in",
                                backgroundColor: Color(0xFFFDC003),
                                foregroundColor: Color(0xFF3D2B00),
                                bottomBorderColor: Color(0xFFD4A200),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginPage(
                                        battleService: battleService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _WelcomeActionButton(
                                label: "Register",
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF1A1C19),
                                bottomBorderColor: Color(0xFFE0E0DB),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OnboardingLanguagePage(
                                        battleService: battleService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _PaperFiberPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeActionButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color bottomBorderColor;
  final VoidCallback onPressed;

  const _WelcomeActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.bottomBorderColor,
    required this.onPressed,
  });

  @override
  State<_WelcomeActionButton> createState() => _WelcomeActionButtonState();
}

class _WelcomeActionButtonState extends State<_WelcomeActionButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedSlide(
        offset: _isPressed ? const Offset(0, 0.04) : Offset.zero,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onPressed,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border(
                  bottom: BorderSide(
                    color: _isPressed
                        ? Colors.transparent
                        : widget.bottomBorderColor,
                    width: 6,
                  ),
                ),
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0,
                  color: widget.foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperFiberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1C19).withValues(alpha: 0.018)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 8), paint);
    }

    for (double x = 6; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x - 8, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
