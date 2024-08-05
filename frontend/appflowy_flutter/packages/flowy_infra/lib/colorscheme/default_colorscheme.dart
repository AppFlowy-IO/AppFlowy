import 'package:flutter/material.dart';

import 'colorscheme.dart';

class ColorSchemeConstants {
  static const white = Color(0xFFFFFFFF);
  static const lightHover = Color(0xFFe0f8FF);
  static const lightSelector = Color(0xFFf2fcFF);
  static const lightBg1 = Color(0xFFf7f8fc);
  static const lightBg2 = Color(0x0F1F2329);
  static const lightShader1 = Color(0xFF333333);
  static const lightShader3 = Color(0xFF828282);
  static const lightShader5 = Color(0xFFe0e0e0);
  static const lightShader6 = Color(0xFFf2f2f2);
  static const lightMain1 = Color(0xFF00bcf0);
  static const lightTint9 = Color(0xFFe1fbFF);
  static const darkShader1 = Color(0xFF131720);
  static const darkShader2 = Color(0xFF1A202C);
  static const darkShader3 = Color(0xFF363D49);
  static const darkShader5 = Color(0xFFBBC3CD);
  static const darkShader6 = Color(0xFFF2F2F2);
  static const darkMain1 = Color(0xFF00BCF0);
  static const darkMain2 = Color(0xFF00BCF0);
  static const darkInput = Color(0xFF282E3A);
  static const lightBorderColor = Color(0xFFEDEDEE);
  static const darkBorderColor = Color(0xFF3A3F49);
}

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: ColorSchemeConstants.white,
          hover: ColorSchemeConstants.lightHover,
          selector: ColorSchemeConstants.lightSelector,
          red: const Color(0xFFfb006d),
          yellow: const Color(0xFFFFd667),
          green: const Color(0xFF66cf80),
          shader1: ColorSchemeConstants.lightShader1,
          shader2: const Color(0xFF4f4f4f),
          shader3: ColorSchemeConstants.lightShader3,
          shader4: const Color(0xFFbdbdbd),
          shader5: ColorSchemeConstants.lightShader5,
          shader6: ColorSchemeConstants.lightShader6,
          shader7: ColorSchemeConstants.lightShader1,
          bg1: ColorSchemeConstants.lightBg1,
          bg2: ColorSchemeConstants.lightBg2,
          bg3: const Color(0xFFe2e4eb),
          bg4: const Color(0xFF2c144b),
          tint1: const Color(0xFFe8e0FF),
          tint2: const Color(0xFFFFe7fd),
          tint3: const Color(0xFFFFe7ee),
          tint4: const Color(0xFFFFefe3),
          tint5: const Color(0xFFFFf2cd),
          tint6: const Color(0xFFf5FFdc),
          tint7: const Color(0xFFddFFd6),
          tint8: const Color(0xFFdeFFf1),
          tint9: ColorSchemeConstants.lightTint9,
          main1: ColorSchemeConstants.lightMain1,
          main2: const Color(0xFF00b7ea),
          shadow: const Color.fromRGBO(0, 0, 0, 0.15),
          sidebarBg: ColorSchemeConstants.lightBg1,
          divider: ColorSchemeConstants.lightShader6,
          topbarBg: ColorSchemeConstants.white,
          icon: ColorSchemeConstants.lightShader1,
          text: ColorSchemeConstants.lightShader1,
          secondaryText: const Color(0xFF4f4f4f),
          strongText: Colors.black,
          input: ColorSchemeConstants.white,
          hint: ColorSchemeConstants.lightShader3,
          primary: ColorSchemeConstants.lightMain1,
          onPrimary: ColorSchemeConstants.white,
          hoverBG1: ColorSchemeConstants.lightBg2,
          hoverBG2: ColorSchemeConstants.lightHover,
          hoverBG3: ColorSchemeConstants.lightShader6,
          hoverFG: ColorSchemeConstants.lightShader1,
          questionBubbleBG: ColorSchemeConstants.lightSelector,
          progressBarBGColor: ColorSchemeConstants.lightTint9,
          toolbarColor: ColorSchemeConstants.lightShader1,
          toggleButtonBGColor: ColorSchemeConstants.lightShader5,
          calendarWeekendBGColor: const Color(0xFFFBFBFC),
          gridRowCountColor: ColorSchemeConstants.lightShader1,
          borderColor: ColorSchemeConstants.lightBorderColor,
          scrollbarColor: const Color(0x3F171717),
          scrollbarHoverColor: const Color(0x7F171717),
        );

  const DefaultColorScheme.dark()
      : super(
          surface: ColorSchemeConstants.darkShader2,
          hover: ColorSchemeConstants.darkMain1,
          selector: ColorSchemeConstants.darkShader2,
          red: const Color(0xFFfb006d),
          yellow: const Color(0xFFF7CF46),
          green: const Color(0xFF66CF80),
          shader1: ColorSchemeConstants.darkShader1,
          shader2: ColorSchemeConstants.darkShader2,
          shader3: ColorSchemeConstants.darkShader3,
          shader4: const Color(0xFF505469),
          shader5: ColorSchemeConstants.darkShader5,
          shader6: ColorSchemeConstants.darkShader6,
          shader7: ColorSchemeConstants.white,
          bg1: const Color(0xFF1A202C),
          bg2: const Color(0xFFEDEEF2),
          bg3: ColorSchemeConstants.darkMain1,
          bg4: const Color(0xFF2C144B),
          tint1: const Color(0x4d9327FF),
          tint2: const Color(0x66FC0088),
          tint3: const Color(0x4dFC00E2),
          tint4: const Color(0x80BE5B00),
          tint5: const Color(0x33F8EE00),
          tint6: const Color(0x4d6DC300),
          tint7: const Color(0x5900BD2A),
          tint8: const Color(0x80008890),
          tint9: const Color(0x4d0029FF),
          main1: ColorSchemeConstants.darkMain2,
          main2: const Color(0xFF00B7EA),
          shadow: const Color(0xFF0F131C),
          sidebarBg: const Color(0xFF232B38),
          divider: ColorSchemeConstants.darkShader3,
          topbarBg: ColorSchemeConstants.darkShader1,
          icon: ColorSchemeConstants.darkShader5,
          text: ColorSchemeConstants.darkShader5,
          secondaryText: ColorSchemeConstants.darkShader5,
          strongText: Colors.white,
          input: ColorSchemeConstants.darkInput,
          hint: const Color(0xFF59647a),
          primary: ColorSchemeConstants.darkMain2,
          onPrimary: ColorSchemeConstants.darkShader1,
          hoverBG1: const Color(0x1AFFFFFF),
          hoverBG2: ColorSchemeConstants.darkMain1,
          hoverBG3: ColorSchemeConstants.darkShader3,
          hoverFG: const Color(0xE5FFFFFF),
          questionBubbleBG: ColorSchemeConstants.darkShader3,
          progressBarBGColor: ColorSchemeConstants.darkShader3,
          toolbarColor: ColorSchemeConstants.darkInput,
          toggleButtonBGColor: const Color(0xFF828282),
          calendarWeekendBGColor: ColorSchemeConstants.darkShader1,
          gridRowCountColor: ColorSchemeConstants.darkShader5,
          borderColor: ColorSchemeConstants.darkBorderColor,
          scrollbarColor: const Color(0x40FFFFFF),
          scrollbarHoverColor: const Color(0x80FFFFFF),
        );
}
