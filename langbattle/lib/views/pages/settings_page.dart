import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:langbattle/data/constants.dart';
import 'package:langbattle/data/notifiers.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langbattle/views/pages/welcome_page.dart';

class SettingsPage extends StatefulWidget {
  final BattleService? battleService;
  const SettingsPage({super.key, this.battleService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Map<String, String> _languageLabels = {
    'en': 'languageEnglish',
    'de': 'languageGerman',
    'fr': 'languageFrench',
    'ro': 'languageRomanian',
  };

  late TextEditingController _nameController;
  bool _nameSaving = false;
  bool _avatarUploading = false;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.battleService?.currentUser?.name ?? '',
    );
    _sub = widget.battleService?.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'avatar_updated') {
        setState(() => _avatarUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
      if (event['type'] == 'error') {
        setState(() {
          _nameSaving = false;
          _avatarUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event['message']?.toString() ?? 'Something went wrong')),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _setTheme(bool isDark) async {
    isDarkModeNotifier.value = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Kconstants.themeModeKey, isDark);
  }

  Future<void> _setUiLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Kconstants.localeKey, locale.languageCode);
  }

  void _saveName() {
    final service = widget.battleService;
    if (service == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == service.currentUser?.name) return;
    setState(() => _nameSaving = true);
    service.currentUser = service.currentUser?.copyWith(name: newName);
    setState(() => _nameSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Display name updated')),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final service = widget.battleService;
    if (service == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _avatarUploading = true);

    try {
      Uint8List bytes;

      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      } else {
        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: 300,
          minHeight: 300,
          quality: 80,
          format: CompressFormat.jpeg,
        );
        if (compressed == null) {
          setState(() => _avatarUploading = false);
          return;
        }
        bytes = compressed;
      }

      if (bytes.length > 500000) {
        setState(() => _avatarUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large. Please choose a smaller photo.')),
          );
        }
        return;
      }
      final encoded = base64Encode(bytes);
      print('Emitting upload_avatar, base64 length: ${encoded.length}');
      service.uploadAvatar(base64Encode(bytes));
    } catch (e) {
      setState(() => _avatarUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = widget.battleService?.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) ...[
            _SectionHeader(label: 'Profile'),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar row
                    Row(
                      children: [
                        Stack(
                          children: [
                            UserAvatar(
                              name: user.name,
                              base64Image: user.avatarBase64,
                              size: 64,
                              borderRadius: 10,
                            ),
                            if (_avatarUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile picture',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Square images work best',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _avatarUploading ? null : _pickAndUploadAvatar,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(user.avatarBase64 != null ? 'Change' : 'Upload'),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    // Display name
                    Text('Display name',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveName(),
                            decoration: InputDecoration(
                              hintText: 'Enter your display name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _nameSaving ? null : _saveName,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _nameSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          _SectionHeader(label: 'Appearance'),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDark, _) => SwitchListTile.adaptive(
                title: Text(isDark ? 'Dark mode' : 'Light mode'),
                value: isDark,
                onChanged: _setTheme,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 28),

          _SectionHeader(label: 'App language'),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ValueListenableBuilder<Locale?>(
              valueListenable: localeNotifier,
              builder: (context, locale, _) {
                final currentCode = locale?.languageCode ?? 'en';
                final keys = _languageLabels.keys.toList();

                String labelFor(String key) {
                  switch (_languageLabels[key]) {
                    case 'languageEnglish': return loc.languageEnglish;
                    case 'languageGerman':  return loc.languageGerman;
                    case 'languageFrench':  return loc.languageFrench;
                    case 'languageRomanian': return loc.languageRomanian;
                    default: return key;
                  }
                }

                return Column(
                  children: keys.asMap().entries.map((e) {
                    final isFirst = e.key == 0;
                    final isLast = e.key == keys.length - 1;
                    return RadioListTile<String>(
                      title: Text(labelFor(e.value)),
                      value: e.value,
                      groupValue: currentCode,
                      onChanged: (v) { if (v != null) _setUiLocale(Locale(v)); },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: isFirst ? const Radius.circular(12) : Radius.zero,
                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              widget.battleService?.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => WelcomePage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}