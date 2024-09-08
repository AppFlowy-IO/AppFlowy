import 'package:flutter/material.dart';

import 'chat_input.dart';

const double sendButtonSize = 26;
const double attachButtonSize = 26;
const buttonPadding = EdgeInsets.symmetric(horizontal: 2);
const inputPadding = EdgeInsets.all(6);
final textPadding = isMobile
    ? const EdgeInsets.only(left: 8.0, right: 4.0)
    : const EdgeInsets.symmetric(horizontal: 16);
final borderRadius = BorderRadius.circular(30);
const color = Colors.transparent;
