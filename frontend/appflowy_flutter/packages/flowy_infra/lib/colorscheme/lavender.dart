import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);

const _lightHover = Color(0xffd8d6fc);
const _lightSelector = Color(0xffe5e3f9);
const _lightBg1 = Color(0xfff2f0f6);
const _lightBg2 = Color(0xffd8d6fc);
const _lightShader1 = Color(0xff333333);
const _lightShader3 = Color(0xff828282);
const _lightShader5 = Color(0xffe0e0e0);
const _lightShader6 = Color(0xffd8d6fc);
const _lightMain1 = Color(0xffaba9e7);
const _lightTint9 = Color(0xffe1fbff);

const _darkShader1 = Color(0xff131720);
const _darkShader2 = Color(0xff1A202C);
const _darkShader3 = Color(0xff363D49);
const _darkShader5 = Color(0xffBBC3CD);
const _darkShader6 = Color(0xffF2F2F2);
const _darkMain1 = Color(0xffab00ff);
const _darkInput = Color(0xff282E3A);

class LavenderColorScheme extends FlowyColorScheme {
  const LavenderColorScheme.light()
      : super(
          surface: Colors.white,
          hover: _lightHover,
          selector: _lightSelector,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: const Color(0xff333333),
          shader2: const Color(0xff4f4f4f),
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: _lightShader5,
          shader6: const Color(0xfff2f2f2),
          shader7: _black,
          bg1: const Color(0xffAC59FF),
          bg2: const Color(0xffedeef2),
          bg3: _lightHover,
          bg4: const Color(0xff2c144b),
          tint1: const Color(0xffe8e0ff),
          tint2: const Color(0xffffe7fd),
          tint3: const Color(0xffffe7ee),
          tint4: const Color(0xffffefe3),
          tint5: const Color(0xfffff2cd),
          tint6: const Color(0xfff5ffdc),
          tint7: const Color(0xffddffd6),
          tint8: const Color(0xffdefff1),
          tint9: _lightMain1,
          main1: _lightMain1,
          main2: _lightMain1,
          shadow: const Color.fromRGBO(0, 0, 0, 0.15),
          sidebarBg: _lightBg1,
          divider: _lightShader6,
          topbarBg: _white,
          icon: _lightShader1,
          text: _lightShader1,
          secondaryText: _lightShader1,
          strongText: Colors.black,
          input: _white,
          hint: _lightShader3,
          primary: _lightMain1,
          onPrimary: _lightShader1,
          hoverBG1: _lightBg2,
          hoverBG2: _lightHover,
          hoverBG3: _lightShader6,
          hoverFG: _lightShader1,
          questionBubbleBG: _lightSelector,
          progressBarBGColor: _lightTint9,
          toolbarColor: _lightShader1,
          toggleButtonBGColor: _lightSelector,
          calendarWeekendBGColor: const Color(0xFFFBFBFC),
          gridRowCountColor: _black,
          borderColor: ColorSchemeConstants.lightBorderColor,
          scrollbarColor: const Color(0x3F171717),
          scrollbarHoverColor: const Color(0x7F171717),
        );

  const LavenderColorScheme.dark()
      : super(
          surface: const Color(0xFF1B1A1D),
          hover: _darkMain1,
          selector: _darkShader2,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: _white,
          shader2: _darkShader2,
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: _white,
          shader6: _darkShader6,
          shader7: _white,
          bg1: const Color(0xff8C23F6),
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
          sidebarBg: const Color(0xff2D223B),
          divider: _darkShader3,
          topbarBg: _darkShader1,
          icon: _darkShader5,
          text: _darkShader5,
          secondaryText: _darkShader5,
          strongText: Colors.white,
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
          borderColor: ColorSchemeConstants.darkBorderColor,
          scrollbarColor: const Color(0x40FFFFFF),
          scrollbarHoverColor: const Color(0x80FFFFFF),
        );
}
