import 'package:flutter/material.dart';

import 'colorscheme.dart';

const _black = Color(0xff000000);
const _white = Color(0xFFFFFFFF);

class DefaultColorScheme extends FlowyColorScheme {
  const DefaultColorScheme.light()
      : super(
          surface: _white,
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
          shader7: _white,
          bg1: const Color(0xfff7f8fc),
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

  const DefaultColorScheme.dark()
      : super(
          surface: const Color(0xff292929),
          hover: const Color(0xffE0F8FF),
          selector: const Color(0xffF2FCFF),
          red: const Color(0xfffb006d),
          yellow: const Color(0xffffd667),
          green: const Color(0xff66cf80),
          shader1: const Color(0xff7C8CA5),
          shader2: const Color(0xff4F4F4F),
          shader3: const Color(0xff828282),
          shader4: const Color(0xffBDBDBD),
          shader5: const Color(0xffE0E0E0),
          shader6: const Color(0xffF2F2F2),
          shader7: _white,
          bg1: const Color(0xffF7F8FC),
          bg2: const Color(0xffEDEEF2),
          bg3: const Color(0xffE2E4EB),
          bg4: const Color(0xff2C144B),
          tint1: const Color(0xffE8E0FF),
          tint2: const Color(0xffFFE7FD),
          tint3: const Color(0xffFFE7EE),
          tint4: const Color(0xffFFEFE3),
          tint5: const Color(0xffFFF2CD),
          tint6: const Color(0xffF5FFDC),
          tint7: const Color(0xffDDFFD6),
          tint8: const Color(0xffDEFFF1),
          tint9: const Color(0xffE1FBFF),
          main1: const Color(0xff00BCF0),
          main2: const Color(0xff00B7EA),
          shadow: _black,
        );
}
