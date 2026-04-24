// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get language => 'Français';

  @override
  String get battleNow => 'Combattre maintenant';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String ratingForLanguage(String languageLabel, String rating) {
    return 'Classement ($languageLabel) : $rating';
  }

  @override
  String get loginToSeeRating => 'Connectez-vous pour voir votre classement.';

  @override
  String get waitingForOpponent => 'En attente de l\'adversaire...';

    @override
    String get reviewAnswers => 'Revoir les réponses';
  

  @override
  String battleRound(int round) {
    return 'Manche de combat $round';
  }

  @override
  String timeLeft(int seconds) {
    return 'Temps restant : $seconds s';
  }

  @override
  String scoreLine(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Score : $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String gameOverSummary(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Fin de la partie !\n$meName: $meScore | $opponentName: $opponentScore';
  }

  @override
  String get returnToHome => 'Retour à l\'accueil';

  @override
  String get youFinishedWaitingOpponent => 'Vous avez terminé toutes les questions.\nEn attente que l\'adversaire termine...';

  @override
  String currentScore(String meName, int meScore, String opponentName, int opponentScore) {
    return 'Score actuel : $meName $meScore - $opponentName $opponentScore';
  }

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRomanian => 'Roumain';
}
