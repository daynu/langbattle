import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/widget_tree.dart';

// ─────────────────────────────────────────────
// Step 1 — Language selection
// ─────────────────────────────────────────────

class OnboardingLanguagePage extends StatelessWidget {
  final BattleService battleService;

  const OnboardingLanguagePage({super.key, required this.battleService});

  static const List<Map<String, String>> _languages = [
    {'key': 'german', 'label': 'German', 'flag': '🇩🇪'},
    {'key': 'french', 'label': 'French', 'flag': '🇫🇷'},
    {'key': 'english', 'label': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Which language do\nyou want to learn?',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You can always add more languages later.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              ..._languages.map((lang) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OptionCard(
                      leading: Text(lang['flag']!,
                          style: const TextStyle(fontSize: 32)),
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
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 2 — Level selection
// ─────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'CEFR',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _showCefr,
                  onChanged: (v) => setState(() => _showCefr = v),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'What\'s your ${widget.languageLabel} level?',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Be honest — you\'ll be matched with players at your level.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: _levels.map((level) {
                    final title = _showCefr
                        ? '${level['cefr']} — ${level['label']}'
                        : level['label'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionCard(
                        leading: _showCefr
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    level['cefr'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              )
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
    );
  }
}

// ─────────────────────────────────────────────
// Step 3 — Credentials
// ─────────────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'auth_success') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WidgetTree(battleService: widget.battleService),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Create your account',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              // Summary chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Learning ${widget.selectedLanguage[0].toUpperCase()}${widget.selectedLanguage.substring(1)} · ${widget.levelLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Register button
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create account',
                    style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              // Google placeholder
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Google sign-in coming soon')),
                  );
                },
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared option card widget
// ─────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}