import 'package:flutter/material.dart';
import 'package:langbattle/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}



