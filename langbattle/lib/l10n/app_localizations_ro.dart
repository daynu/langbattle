// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get language => 'Română';

  @override
  String get battleNow => 'Luptă acum';

  @override
  String get selectLanguage => 'Alege limba';

  @override
  String ratingForLanguage(String languageLabel, String rating) {
    return 'Rating ($languageLabel): $rating';
  }

  @override
  String get loginToSeeRating => 'Autentifică-te pentru a-ți vedea ratingul.';

  @override
  String get waitingForOpponent => 'Se așteaptă adversarul...';

  @override
  String battleRound(int round) {
    return 'Runda de luptă $round';
  }

  @override
  String timeLeft(int seconds) {
    return 'Timp rămas: $seconds s';
  }

  @override
  String get reviewAnswers => 'Revizuiește răspunsurile';


  @override
  String scoreLine(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Scor: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String gameOverSummary(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Joc terminat!\n$meName: $meScore | $opponentName: $opponentScore';
  }

  @override
  String get returnToHome => 'Înapoi la acasă';

  @override
  String get youFinishedWaitingOpponent => 'Ai terminat toate întrebările.\nSe așteaptă ca adversarul să termine...';

  @override
  String currentScore(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Scor curent: $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String get languageEnglish => 'Engleză';

  @override
  String get languageGerman => 'Germană';

  @override
  String get languageFrench => 'Franceză';

  @override
  String get languageRomanian => 'Română';
}
