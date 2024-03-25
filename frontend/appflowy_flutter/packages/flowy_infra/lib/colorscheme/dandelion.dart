import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);
const _lightBg1 = Color(0xFFFFD13E);
const _lightShader1 = Color(0xff333333);
const _lightShader3 = Color(0xff828282);
const _lightShader5 = Color(0xffe0e0e0);
const _lightShader6 = Color(0xfff2f2f2);
const _lightDandelionYellow = Color(0xffffcb00);
const _lightDandelionLightYellow = Color(0xffffdf66);
const _lightDandelionGreen = Color(0xff9bc53d);
const _lightTint9 = Color(0xffe1fbff);

const _darkShader1 = Color(0xff131720);
const _darkShader2 = Color(0xff1A202C);
const _darkShader3 = Color(0xff363D49);
const _darkShader5 = Color(0xffBBC3CD);
const _darkShader6 = Color(0xffF2F2F2);
const _darkMain1 = Color(0xffffcb00);
const _darkInput = Color(0xff282E3A);

class DandelionColorScheme extends FlowyColorScheme {
  const DandelionColorScheme.light()
      : super(
          surface: Colors.white,
          hover: const Color(0xFFe0f8ff),
          // hover effect on setting value
          selector: _lightDandelionLightYellow,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: const Color(0xff333333),
          shader2: const Color(0xff4f4f4f),
          shader3: const Color(0xff828282),
          // disable text color
          shader4: const Color(0xffbdbdbd),
          shader5: _lightShader5,
          shader6: const Color(0xfff2f2f2),
          shader7: _black,
          bg1: _lightBg1,
          bg2: const Color(0xffedeef2),
          // Hover color on trash button
          bg3: _lightDandelionYellow,
          bg4: const Color(0xff2c144b),
          tint1: const Color(0xffe8e0ff),
          tint2: const Color(0xffffe7fd),
          tint3: const Color(0xffffe7ee),
          tint4: const Color(0xffffefe3),
          tint5: const Color(0xfffff2cd),
          tint6: const Color(0xfff5ffdc),
          tint7: const Color(0xffddffd6),
          tint8: const Color(0xffdefff1),
          tint9: _lightTint9,
          main1: _lightDandelionYellow,
          // cursor color
          main2: _lightDandelionYellow,
          shadow: const Color.fromRGBO(0, 0, 0, 0.15),
          sidebarBg: _lightDandelionGreen,
          divider: _lightShader6,
          topbarBg: _white,
          icon: _lightShader1,
          text: _lightShader1,
          secondaryText: _lightShader1,
          input: _white,
          hint: _lightShader3,
          primary: _lightDandelionYellow,
          onPrimary: _lightShader1,
          // hover color in sidebar
          hoverBG1: _lightDandelionYellow,
          // tool bar hover color
          hoverBG2: _lightDandelionLightYellow,
          hoverBG3: _lightShader6,
          hoverFG: _lightShader1,
          questionBubbleBG: _lightDandelionLightYellow,
          progressBarBGColor: _lightTint9,
          toolbarColor: _lightShader1,
          toggleButtonBGColor: _lightDandelionYellow,
          calendarWeekendBGColor: const Color(0xFFFBFBFC),
          gridRowCountColor: _black,
        );

  const DandelionColorScheme.dark()
      : super(
          surface: const Color(0xff292929),
          hover: const Color(0xff1f1f1f),
          selector: _darkShader2,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: _white,
          shader2: _darkShader2,
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: _darkShader5,
          shader6: _darkShader6,
          shader7: _white,
          bg1: const Color(0xFFD5A200),
          bg2: _black,
          bg3: _darkMain1,
          bg4: const Color(0xff2c144b),
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
          main2: _darkMain1,
          shadow: const Color(0xff0F131C),
          sidebarBg: const Color(0xff25300e),
          divider: _darkShader3,
          topbarBg: _darkShader1,
          icon: _darkShader5,
          text: _darkShader5,
          secondaryText: _darkShader5,
          input: _darkInput,
          hint: _darkShader5,
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
          calendarWeekendBGColor: const Color(0xff121212),
          gridRowCountColor: _darkMain1,
        );
}
