import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _white = Color(0xFFFFFFFF);
const _lightHover = Color(0xFFe0f8FF);
const _lightSelector = Color(0xFFf2fcFF);
const _lightBg1 = Color(0xFFf7f8fc);
const _lightBg2 = Color(0xFFedeef2);
const _lightShader1 = Color(0xFF333333);
const _lightShader3 = Color(0xFF828282);
const _lightShader5 = Color(0xFFe0e0e0);
const _lightShader6 = Color(0xFFf2f2f2);
const _lightMain1 = Color(0xFF00bcf0);
const _lightTint9 = Color(0xFFe1fbFF);
const _darkShader1 = Color(0xFF131720);
const _darkShader2 = Color(0xFF1A202C);
const _darkShader3 = Color(0xFF363D49);
const _darkShader5 = Color(0xFFBBC3CD);
const _darkShader6 = Color(0xFFF2F2F2);
const _darkMain1 = Color(0xFF00BCF0);
const _darkInput = Color(0xFF282E3A);

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: _white,
          hover: _lightHover,
          selector: _lightSelector,
          red: const Color(0xFFfb006d),
          yellow: const Color(0xFFFFd667),
          green: const Color(0xFF66cf80),
          shader1: _lightShader1,
          shader2: const Color(0xFF4f4f4f),
          shader3: _lightShader3,
          shader4: const Color(0xFFbdbdbd),
          shader5: _lightShader5,
          shader6: _lightShader6,
          shader7: _lightShader1,
          bg1: _lightBg1,
          bg2: _lightBg2,
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
          tint9: _lightTint9,
          main1: _lightMain1,
          main2: const Color(0xFF00b7ea),
          shadow: const Color.fromRGBO(0, 0, 0, 0.15),
          sidebarBg: _lightBg1,
          divider: _lightShader6,
          topbarBg: _white,
          icon: _lightShader1,
          text: _lightShader1,
          secondaryText: const Color(0xFF4f4f4f),
          input: _white,
          hint: _lightShader3,
          primary: _lightMain1,
          onPrimary: _white,
          hoverBG1: _lightBg2,
          hoverBG2: _lightHover,
          hoverBG3: _lightShader6,
          hoverFG: _lightShader1,
          questionBubbleBG: _lightSelector,
          progressBarBGColor: _lightTint9,
          toolbarColor: _lightShader1,
          toggleButtonBGColor: _lightShader5,
          calendarWeekendBGColor: const Color(0xFFFBFBFC),
          gridRowCountColor: _lightShader1,
        );

  const DefaultColorScheme.dark()
      : super(
          surface: _darkShader2,
          hover: _darkMain1,
          selector: _darkShader2,
          red: const Color(0xFFfb006d),
          yellow: const Color(0xFFF7CF46),
          green: const Color(0xFF66CF80),
          shader1: _darkShader1,
          shader2: _darkShader2,
          shader3: _darkShader3,
          shader4: const Color(0xFF505469),
          shader5: _darkShader5,
          shader6: _darkShader6,
          shader7: _white,
          bg1: const Color(0xFF1A202C),
          bg2: const Color(0xFFEDEEF2),
          bg3: _darkMain1,
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
          main1: _darkMain1,
          main2: const Color(0xFF00B7EA),
          shadow: const Color(0xFF0F131C),
          sidebarBg: const Color(0xFF232B38),
          divider: _darkShader3,
          topbarBg: _darkShader1,
          icon: _darkShader5,
          text: _darkShader5,
          secondaryText: _darkShader5,
          input: _darkInput,
          hint: const Color(0xFF59647a),
          primary: _darkMain1,
          onPrimary: _darkShader1,
          hoverBG1: _darkMain1,
          hoverBG2: _darkMain1,
          hoverBG3: _darkShader3,
          hoverFG: _darkShader1,
          questionBubbleBG: _darkShader3,
          progressBarBGColor: _darkShader3,
          toolbarColor: _darkInput,
          toggleButtonBGColor: _darkShader1,
          calendarWeekendBGColor: _darkShader1,
          gridRowCountColor: _darkShader5,
        );
}
