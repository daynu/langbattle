import 'package:flutter/material.dart';
import 'package:langbattle/data/constants.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/data/notifiers.dart';
import 'package:langbattle/views/rootScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:langbattle/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("auth_token");
  final bool? themeMode = prefs.getBool(Kconstants.themeModeKey);
  final String? savedLocaleCode = prefs.getString(Kconstants.localeKey);
  isDarkModeNotifier.value = themeMode ?? false;
  if (savedLocaleCode != null && savedLocaleCode.isNotEmpty) {
    localeNotifier.value = Locale(savedLocaleCode);
  }

  print("Restored token: $token");



  final BattleService battleService = BattleService();
  battleService.connect();


  runApp(MyApp(
    
    battleService: battleService,
    token: token,
  ));
}



class MyApp extends StatefulWidget {
  final BattleService battleService;
  final String? token;  

  const MyApp({
    super.key,
    required this.battleService,
    this.token,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDarkMode, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'Poppins',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.tealAccent,
                  brightness: isDarkMode ? Brightness.dark : Brightness.light,
                ),
              ),
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: RootScreen(battleService: widget.battleService, token: widget.token), // no token → show login/register
            );
          },
        );
      },
    );
  }
}