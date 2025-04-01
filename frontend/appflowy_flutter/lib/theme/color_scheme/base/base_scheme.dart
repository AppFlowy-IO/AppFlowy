import 'package:appflowy/theme/color_scheme/base/blue.dart';
import 'package:appflowy/theme/color_scheme/base/green.dart';
import 'package:appflowy/theme/color_scheme/base/magenta.dart';
import 'package:appflowy/theme/color_scheme/base/neutral.dart';
import 'package:appflowy/theme/color_scheme/base/orange.dart';
import 'package:appflowy/theme/color_scheme/base/purple.dart';
import 'package:appflowy/theme/color_scheme/base/red.dart';
import 'package:appflowy/theme/color_scheme/base/subtle.dart';
import 'package:appflowy/theme/color_scheme/base/yellow.dart';

class AppFlowyBaseColorScheme {
  const AppFlowyBaseColorScheme({
    this.blue = const BlueColors(),
    this.green = const GreenColors(),
    this.yellow = const YellowColors(),
    this.red = const RedColors(),
    this.orange = const OrangeColors(),
    this.magenta = const MagentaColors(),
    this.purple = const PurpleColors(),
    this.neutral = const NeutralColors(),
    this.subtle = const SubtleColors(),
  });

  final BlueColors blue;
  final GreenColors green;
  final YellowColors yellow;
  final RedColors red;
  final OrangeColors orange;
  final MagentaColors magenta;
  final PurpleColors purple;
  final NeutralColors neutral;
  final SubtleColors subtle;
}
