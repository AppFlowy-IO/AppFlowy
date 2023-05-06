import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _white = Color(0xFFFFFFFF);
const _lightHover = Color(0xFFe0f8ff);
const _lightSelector = Color(0xfff2fcff);
const _lightBg1 = Color(0xfff7f8fc);
const _lightBg2 = Color(0xffedeef2);
const _lightShader1 = Color(0xff333333);
const _lightShader3 = Color(0xff828282);
const _lightShader5 = Color(0xffe0e0e0);
const _lightShader6 = Color(0xfff2f2f2);
const _lightMain1 = Color(0xff00bcf0);
const _lightTint9 = Color(0xffe1fbff);
const _darkShader1 = Color(0xff131720);
const _darkShader2 = Color(0xff1A202C);
const _darkShader3 = Color(0xff363D49);
const _darkShader5 = Color(0xffBBC3CD);
const _darkShader6 = Color(0xffF2F2F2);
const _darkMain1 = Color(0xff00BCF0);
const _darkInput = Color(0xff282E3A);

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: _white,
          hover: _lightHover,
          selector: _lightSelector,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: _lightShader1,
          shader2: const Color(0xff4f4f4f),
          shader3: _lightShader3,
          shader4: const Color(0xffbdbdbd),
          shader5: _lightShader5,
          shader6: _lightShader6,
          shader7: _lightShader1,
          bg1: _lightBg1,
          bg2: _lightBg2,
          bg3: const Color(0xffe2e4eb),
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
          main1: _lightMain1,
          main2: const Color(0xff00b7ea),
          shadow: const Color.fromRGBO(0, 0, 0, 0.15),
          sidebarBg: _lightBg1,
          divider: _lightShader6,
          topbarBg: _white,
          icon: _lightShader1,
          text: _lightShader1,
          input: _white,
          hint: _lightShader3,
          primary: _lightMain1,
          onPrimary: _white,
          hoverBG1: _lightBg2,
          hoverBG2: _lightHover,
          hoverFG: _lightShader1,
          questionBubbleBG: _lightSelector,
          hoverBG3: _lightShader6,
          progressBarBGColor: _lightTint9,
          toolbarColor: _lightShader1,
          toggleButtonBGColor: _lightShader5,
        );

  const DefaultColorScheme.dark()
      : super(
          surface: _darkShader2,
          hover: _darkMain1,
          selector: _darkShader2,
          red: const Color(0xfffb006d),
          yellow: const Color(0xffF7CF46),
          green: const Color(0xff66CF80),
          shader1: _darkShader1,
          shader2: _darkShader2,
          shader3: _darkShader3,
          shader4: const Color(0xff7C8CA5),
          shader5: _darkShader5,
          shader6: _darkShader6,
          shader7: _white,
          bg1: const Color(0xffF7F8FC),
          bg2: const Color(0xffEDEEF2),
          bg3: _darkMain1,
          bg4: const Color(0xff2C144B),
          tint1: const Color(0xff8738F5),
          tint2: const Color(0xffE6336E),
          tint3: const Color(0xffFF2D9E),
          tint4: const Color(0xffE9973E),
          tint5: const Color(0xffFBF000),
          tint6: const Color(0xffC0F000),
          tint7: const Color(0xff15F74E),
          tint8: const Color(0xff00F0E2),
          tint9: const Color(0xff00BCF0),
          main1: _darkMain1,
          main2: const Color(0xff00B7EA),
          shadow: const Color(0xff0F131C),
          sidebarBg: const Color(0xff232B38),
          divider: _darkShader3,
          topbarBg: _darkShader1,
          icon: _darkShader5,
          text: _darkShader5,
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
        );
}
