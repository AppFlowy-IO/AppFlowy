import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);
const _lightBg1 = Color(0xfff7f8fc);
const _lightShader1 = Color(0xff333333);
const _lightShader6 = Color(0xfff2f2f2);
const _darkShader1 = Color(0xff131720);
const _darkShader2 = Color(0xff1A202C);
const _darkShader3 = Color(0xff363D49);
const _darkShader5 = Color(0xffBBC3CD);
const _darkShader6 = Color(0xffF2F2F2);

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: _white,
          hover: const Color(0xFFe0f8ff),
          selector: const Color(0xfff2fcff),
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: _lightShader1,
          shader2: const Color(0xff4f4f4f),
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: const Color(0xffe0e0e0),
          shader6: _lightShader6,
          shader7: _white,
          bg1: _lightBg1,
          bg2: const Color(0xffedeef2),
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
          tint9: const Color(0xffe1fbff),
          main1: const Color(0xff00bcf0),
          main2: const Color(0xff00b7ea),
          shadow: _black,
          sidebarBg: _lightBg1,
          divider: _lightShader6,
          topbarBg: _white,
          icon: _lightShader1,
          text: _lightShader1,
        );

  const DefaultColorScheme.dark()
      : super(
          surface: _darkShader2,
          hover: const Color(0xffE0F8FF),
          selector: const Color(0xffF2FCFF),
          red: const Color(0xfffb006d),
          yellow: const Color(0xffF7CF46),
          green: const Color(0xff66CF80),
          shader1: _darkShader1,
          shader2: _darkShader2,
          shader3: _darkShader3,
          shader4: const Color(0xff7C8CA5),
          shader5: const Color(0xffBBC3CD),
          shader6: _darkShader6,
          shader7: _white,
          bg1: const Color(0xffF7F8FC),
          bg2: const Color(0xffEDEEF2),
          bg3: const Color(0xffE2E4EB),
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
          main1: const Color(0xff00BCF0),
          main2: const Color(0xff00B7EA),
          shadow: _black,
          sidebarBg: const Color(0xff232B38),
          divider: _darkShader3,
          topbarBg: _darkShader1,
          icon: _darkShader6,
          text: _darkShader5,
        );
}
