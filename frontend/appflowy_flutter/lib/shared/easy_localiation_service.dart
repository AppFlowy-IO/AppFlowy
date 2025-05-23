import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:flutter/widgets.dart';

class EasyLocalizationService {
  EasyLocalizationService();

  late EasyLocalizationController? controller;

  String getFallbackTranslation(String token) {
    final translations = controller?.fallbackTranslations;

    return translations?.get(token).toString() ?? '';
  }

  String getTranslation(String token) {
    final translations = controller?.translations;

    return translations?.get(token).toString() ?? '';
  }

  void init(BuildContext context) {
    controller = EasyLocalization.of(context)?.delegate.localizationController;
  }
}
