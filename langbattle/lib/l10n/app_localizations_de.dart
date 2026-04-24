// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get language => 'Deutsch';

  @override
  String get battleNow => 'Jetzt kämpfen';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String ratingForLanguage(String languageLabel, String rating) {
    return 'Wertung ($languageLabel): $rating';
  }

  @override
  String get loginToSeeRating => 'Melde dich an, um deine Wertung zu sehen.';

  @override
  String get waitingForOpponent => 'Warte auf einen Gegner...';

  @override
  String get reviewAnswers => 'Antworten überprüfen';


  @override
  String battleRound(int round) {
    return 'Kampfrunde $round';
  }

  @override
  String timeLeft(int seconds) {
    return 'Verbleibende Zeit: $seconds s';
  }

  @override
  String scoreLine(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Punktestand: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String gameOverSummary(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Spiel vorbei!\n$meName: $meScore | $opponentName: $opponentScore';
  }

  @override
  String get returnToHome => 'Zurück zum Start';

  @override
  String get youFinishedWaitingOpponent => 'Du hast alle Fragen beendet.\nWarte, bis der Gegner fertig ist...';

  @override
  String currentScore(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Aktueller Punktestand: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageRomanian => 'Rumänisch';
}
