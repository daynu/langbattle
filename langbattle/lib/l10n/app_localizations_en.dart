// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get battleNow => 'Battle Now';

  @override
  String get selectLanguage => 'Select language';

  @override
  String ratingForLanguage(String languageLabel, String rating) {
    return 'Rating ($languageLabel): $rating';
  }

  @override
  String get loginToSeeRating => 'Log in to see your rating.';

  @override
  String get waitingForOpponent => 'Waiting for opponent...';

  @override
  String battleRound(int round) {
    return 'Battle Round $round';
  }

  @override
  String timeLeft(int seconds) {
    return 'Time left: $seconds s';
  }

  @override
  String scoreLine(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Score: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String gameOverSummary(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Game Over!\\n$meName: $meScore | $opponentName: $opponentScore';
  }

  @override
  String get returnToHome => 'Return to Home';
  String get reviewAnswers => 'Review Answers';

  @override
  String get youFinishedWaitingOpponent => 'You have completed all questions.\\nWaiting for opponent to finish...';

  @override
  String currentScore(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Current score: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get languageFrench => 'French';

  @override
  String get languageRomanian => 'Romanian';
}
