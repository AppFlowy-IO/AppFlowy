import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);

class LavenderColorScheme extends FlowyColorScheme {
  const LavenderColorScheme.light()
      : super(
          surface: Colors.white,
          hover: const Color(0xFFe0f8ff),
          selector: const Color(0xfff2fcff),
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: const Color(0xff333333),
          shader2: const Color(0xff4f4f4f),
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: const Color(0xffe0e0e0),
          shader6: const Color(0xfff2f2f2),
          shader7: const Color(0xffffffff),
          bg1: const Color(0xffA74EFF),
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
        );

  const LavenderColorScheme.dark()
      : super(
          surface: const Color(0xFF1B1A1D),
          hover: const Color(0xff1f1f1f),
          selector: const Color(0xff333333),
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: _white,
          shader2: const Color(0xffffffff),
          shader3: const Color(0xff828282),
          shader4: const Color(0xffbdbdbd),
          shader5: _white,
          shader6: _black,
          shader7: _black,
          bg1: const Color(0xff9327ff),
          bg2: _black,
          bg3: const Color(0xff4f4f4f),
          bg4: const Color(0xff2c144b),
          tint1: const Color(0xffc3adff),
          tint2: const Color(0xffffadf9),
          tint3: const Color(0xffffadad),
          tint4: const Color(0xffffcfad),
          tint5: const Color(0xfffffead),
          tint6: const Color(0xffe6ffa3),
          tint7: const Color(0xffbcffad),
          tint8: const Color(0xffadffe2),
          tint9: const Color(0xffade4ff),
          main1: const Color(0xff00bcf0),
          main2: const Color(0xff009cc7),
          shadow: _black,
        );
}
