import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/widget_tree.dart';
import 'package:langbattle/widgets/language_flag.dart';
import 'package:lottie/lottie.dart';

class OnboardingLanguagePage extends StatelessWidget {
  final BattleService battleService;

  const OnboardingLanguagePage({super.key, required this.battleService});

  static const List<Map<String, String>> _languages = [
    {'key': 'german', 'label': 'German'},
    {'key': 'french', 'label': 'French'},
    {'key': 'english', 'label': 'English'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OnboardingRegisterPageState._background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 24,
              child: _SignupBackButton(onPressed: () => Navigator.pop(context)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose language',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 42,
                          height: 1.1,
                          letterSpacing: 0,
                          color: _OnboardingRegisterPageState._onBackground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pick the language you want to battle in first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          letterSpacing: 0,
                          color: _OnboardingRegisterPageState._onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ..._languages.map(
                        (lang) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _OptionCard(
                            leading: LanguageFlag(
                              language: lang['key']!,
                              width: 54,
                              height: 38,
                              borderRadius: 12,
                            ),
                            title: lang['label']!,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OnboardingLevelPage(
                                  battleService: battleService,
                                  selectedLanguage: lang['key']!,
                                  languageLabel: lang['label']!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
}

class OnboardingLevelPage extends StatefulWidget {
  final BattleService battleService;
  final String selectedLanguage;
  final String languageLabel;

  const OnboardingLevelPage({
    super.key,
    required this.battleService,
    required this.selectedLanguage,
    required this.languageLabel,
  });

  @override
  State<OnboardingLevelPage> createState() => _OnboardingLevelPageState();
}

class _OnboardingLevelPageState extends State<OnboardingLevelPage> {
  bool _showCefr = false;

  static const List<Map<String, dynamic>> _levels = [
    {
      'key': 'A1',
      'label': 'Complete beginner',
      'description': "I don't know any words yet",
      'cefr': 'A1',
      'rating': 200,
    },
    {
      'key': 'A2',
      'label': 'Some basics',
      'description': 'I know greetings and simple phrases',
      'cefr': 'A2',
      'rating': 400,
    },
    {
      'key': 'B1',
      'label': 'Intermediate',
      'description': 'I can hold simple conversations',
      'cefr': 'B1',
      'rating': 700,
    },
    {
      'key': 'B2',
      'label': 'Upper intermediate',
      'description': 'I understand most topics with some effort',
      'cefr': 'B2',
      'rating': 1000,
    },
    {
      'key': 'C1',
      'label': 'Advanced',
      'description': 'I speak fluently with occasional mistakes',
      'cefr': 'C1',
      'rating': 1400,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OnboardingRegisterPageState._background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 24,
              child: _SignupBackButton(onPressed: () => Navigator.pop(context)),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: _CefrToggle(
                value: _showCefr,
                onChanged: (value) => setState(() => _showCefr = value),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.languageLabel} level',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 42,
                          height: 1.1,
                          letterSpacing: 0,
                          color: _OnboardingRegisterPageState._onBackground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pick the level that feels closest right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          letterSpacing: 0,
                          color: _OnboardingRegisterPageState._onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Expanded(
                        child: ListView(
                          children: _levels.map((level) {
                            final title = _showCefr
                                ? '${level['cefr']} - ${level['label']}'
                                : level['label'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OptionCard(
                                leading: _showCefr
                                    ? _CefrBadge(label: level['cefr'] as String)
                                    : null,
                                title: title,
                                subtitle: level['description'] as String,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OnboardingRegisterPage(
                                      battleService: widget.battleService,
                                      selectedLanguage: widget.selectedLanguage,
                                      startingRating: level['rating'] as int,
                                      levelLabel: level['label'] as String,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
}

class OnboardingRegisterPage extends StatefulWidget {
  final BattleService battleService;
  final String selectedLanguage;
  final int startingRating;
  final String levelLabel;

  const OnboardingRegisterPage({
    super.key,
    required this.battleService,
    required this.selectedLanguage,
    required this.startingRating,
    required this.levelLabel,
  });

  @override
  State<OnboardingRegisterPage> createState() => _OnboardingRegisterPageState();
}

class _OnboardingRegisterPageState extends State<OnboardingRegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  StreamSubscription<Map<String, dynamic>>? _sub;

  static const _background = Color(0xFFF7F7F2);
  static const _onBackground = Color(0xFF2D2F2C);
  static const _onSurfaceVariant = Color(0xFF5A5C58);
  static const _surfaceContainerLow = Color(0xFFF1F1EC);
  static const _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const _primaryContainer = Color(0xFFFDC003);
  static const _onPrimaryContainer = Color(0xFF553E00);
  static const _primary = Color(0xFF755700);
  static const _outlineVariant = Color(0xFFADADA9);

  @override
  void initState() {
    super.initState();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'auth_success') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => WidgetTree(battleService: widget.battleService),
          ),
          (_) => false,
        );
      }
      if (event['type'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event['message'] ?? 'Something went wrong')),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    widget.battleService.register(
      email,
      password,
      name,
      language: widget.selectedLanguage,
      startingRating: widget.startingRating,
    );
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
              child: _SignupBackButton(onPressed: () => Navigator.pop(context)),
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
                      const SizedBox(height: 34),
                      const Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 42,
                          height: 1.1,
                          letterSpacing: 0,
                          color: _onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryChip(),
                      const SizedBox(height: 34),
                      _buildForm(),
                      const SizedBox(height: 30),
                      _buildGooglePlaceholder(),
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
      width: 184,
      height: 184,
      child: Center(
        child: Hero(
          tag: 'hero-image',
          child: Lottie.asset(
            'assets/lotties/#0101FTUE_04.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChip() {
    final language =
        '${widget.selectedLanguage[0].toUpperCase()}${widget.selectedLanguage.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Learning $language / ${widget.levelLabel}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: _onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Column(
        children: [
          _SignupTextField(
            label: 'Nickname',
            hintText: 'Your battle name',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 18),
          _SignupTextField(
            label: 'Email Address',
            hintText: 'hello@langbattle.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 18),
          _SignupTextField(
            label: 'Password',
            hintText: 'Password',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
            trailing: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
          _SignupTactileButton(label: 'Create account', onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildGooglePlaceholder() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0x33ADADA9), height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR CONTINUE WITH',
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
        _SignupGoogleButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google sign-in coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _CefrToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CefrToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: _OnboardingRegisterPageState._surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CEFR',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0,
                  color: _OnboardingRegisterPageState._onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CefrBadge extends StatelessWidget {
  final String label;

  const _CefrBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _OnboardingRegisterPageState._primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0,
            color: _OnboardingRegisterPageState._onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _SignupBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignupBackButton({required this.onPressed});

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
            color: _OnboardingRegisterPageState._surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _OnboardingRegisterPageState._onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SignupTextField extends StatelessWidget {
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

  const _SignupTextField({
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
              color: _OnboardingRegisterPageState._onSurfaceVariant,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _OnboardingRegisterPageState._surfaceContainerLow,
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
              color: _OnboardingRegisterPageState._onBackground,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _OnboardingRegisterPageState._outlineVariant,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: _OnboardingRegisterPageState._onSurfaceVariant,
              ),
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

class _SignupTactileButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _SignupTactileButton({required this.label, required this.onPressed});

  @override
  State<_SignupTactileButton> createState() => _SignupTactileButtonState();
}

class _SignupTactileButtonState extends State<_SignupTactileButton> {
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
                color: _OnboardingRegisterPageState._primary,
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
                    color: _OnboardingRegisterPageState._primaryContainer,
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
                        color: _OnboardingRegisterPageState._onPrimaryContainer,
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

class _SignupGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignupGoogleButton({required this.onPressed});

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
            color: _OnboardingRegisterPageState._surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _OnboardingRegisterPageState._outlineVariant.withValues(
                alpha: 0.2,
              ),
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
                  color: _OnboardingRegisterPageState._surfaceContainerLow,
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _OnboardingRegisterPageState._primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Google',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _OnboardingRegisterPageState._onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: _OnboardingRegisterPageState._surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _OnboardingRegisterPageState._outlineVariant.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: 50, height: 50, child: Center(child: leading!)),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0,
                        color: _OnboardingRegisterPageState._onBackground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: 0,
                          color: _OnboardingRegisterPageState._onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _OnboardingRegisterPageState._surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: _OnboardingRegisterPageState._onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
