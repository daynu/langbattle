import 'package:flutter/material.dart';
import 'package:langbattle/data/constants.dart';
import 'package:langbattle/data/notifiers.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Map<String, String> _languageLabels = {
    "en": "languageEnglish",
    "de": "languageGerman",
    "fr": "languageFrench",
    "ro": "languageRomanian",
  };

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

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDark, _) {
                return SwitchListTile.adaptive(
                  title: Text(
                    isDark ? 'Dark mode' : 'Light mode',
                  ),
                  value: isDark,
                  onChanged: (value) {
                    _setTheme(value);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              loc.selectLanguage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Locale?>(
              valueListenable: localeNotifier,
              builder: (context, locale, _) {
                final currentCode = locale?.languageCode ?? 'en';

                String _labelFor(String key) {
                  switch (_languageLabels[key]) {
                    case 'languageEnglish':
                      return loc.languageEnglish;
                    case 'languageGerman':
                      return loc.languageGerman;
                    case 'languageFrench':
                      return loc.languageFrench;
                    case 'languageRomanian':
                      return loc.languageRomanian;
                    default:
                      return key;
                  }
                }

                return Column(
                  children: _languageLabels.keys.map((code) {
                    return RadioListTile<String>(
                      title: Text(_labelFor(code)),
                      value: code,
                      groupValue: currentCode,
                      onChanged: (value) {
                        if (value == null) return;
                        _setUiLocale(Locale(value));
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}