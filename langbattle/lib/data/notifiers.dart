import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);
ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);
