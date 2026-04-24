import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/onboarding-language-page.dart';
import 'package:langbattle/views/widget_tree.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  final BattleService battleService;

  const LoginPage({super.key, required this.battleService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController controllerEmail = TextEditingController(text: "");
  final TextEditingController controllerPassword = TextEditingController(
    text: "",
  );
  late final StreamSubscription<Map<String, dynamic>> _sub;
  bool _obscurePassword = true;

  static const _background = Color(0xFFF7F7F2);
  static const _onBackground = Color(0xFF2D2F2C);
  static const _onSurfaceVariant = Color(0xFF5A5C58);
  static const _surfaceContainerLow = Color(0xFFF1F1EC);
  static const _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const _primaryContainer = Color(0xFFFDC003);
  static const _onPrimaryContainer = Color(0xFF553E00);
  static const _primary = Color(0xFF755700);
  static const _secondary = Color(0xFFAB2D00);
  static const _outlineVariant = Color(0xFFADADA9);

  @override
  void initState() {
    super.initState();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;

      if (event["type"] == "error") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event["message"]?.toString() ?? "")),
        );
      }

      if (event["type"] == "auth_success") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WidgetTree(battleService: widget.battleService),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 24,
              child: _BackButton(onPressed: () => Navigator.pop(context)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLottieMark(),
                      const SizedBox(height: 40),
                      const Text(
                        "Login",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 44,
                          height: 1.1,
                          letterSpacing: 0,
                          color: _onBackground,
                        ),
                      ),
                      const SizedBox(height: 44),
                      _buildForm(),
                      const SizedBox(height: 32),
                      _buildSocialSection(),
                      const SizedBox(height: 32),
                      _buildFooterLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLottieMark() {
    return SizedBox(
      width: 208,
      height: 208,
      child: Center(
        child: Hero(
          tag: "hero-image",
          child: Lottie.asset(
            'assets/lotties/#0101FTUE_04.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Column(
        children: [
          _LoginTextField(
            label: "Email Address",
            hintText: "hello@langbattle.com",
            icon: Icons.mail_outline_rounded,
            controller: controllerEmail,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 18),
          _LoginTextField(
            label: "Password",
            hintText: "Password",
            icon: Icons.lock_outline_rounded,
            controller: controllerPassword,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
            trailing: IconButton(
              tooltip: _obscurePassword ? "Show password" : "Hide password",
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TactileButton(label: "Log in", onPressed: onLogin),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0x33ADADA9), height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "OR CONTINUE WITH",
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: _outlineVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0x33ADADA9), height: 1)),
          ],
        ),
        const SizedBox(height: 22),
        _GoogleButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Google login is not set up yet")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooterLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "New here? ",
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: _onSurfaceVariant,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: _secondary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OnboardingLanguagePage(battleService: widget.battleService),
              ),
            );
          },
          child: const Text(
            "Create an account",
            style: TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  void onLogin() {
    final email = controllerEmail.text.trim();
    final password = controllerPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    widget.battleService.login(email, password);
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _LoginPageState._surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _LoginPageState._onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _LoginTextField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0,
              color: _LoginPageState._onSurfaceVariant,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _LoginPageState._surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _LoginPageState._onBackground,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _LoginPageState._outlineVariant,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: _LoginPageState._onSurfaceVariant),
              suffixIcon: trailing,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _TactileButton({required this.label, required this.onPressed});

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 72.0;
    const edgeHeight = 6.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight + edgeHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _LoginPageState._primary,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _isPressed ? edgeHeight - 2 : 0,
            height: buttonHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onPressed,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                child: Ink(
                  decoration: BoxDecoration(
                    color: _LoginPageState._primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0,
                        color: _LoginPageState._onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _LoginPageState._surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _LoginPageState._outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LoginPageState._surfaceContainerLow,
                ),
                child: const Text(
                  "G",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _LoginPageState._primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Google",
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _LoginPageState._onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
