import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

const double _smallSize = 28;
const double _largeSize = 56;

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.iconUrl,
    required this.name,
    this.isLarge = false,
  });

  final String iconUrl;
  final String name;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? _largeSize : _smallSize;

    if (iconUrl.isEmpty) {
      final String nameOrDefault = _userName(name);
      final Color color = ColorGenerator().generateColorFromString(name);
      const initialsCount = 2;

      // Taking the first letters of the name components and limiting to 2 elements
      final nameInitials = nameOrDefault
          .split(' ')
          .where((element) => element.isNotEmpty)
          .take(initialsCount)
          .map((element) => element[0].toUpperCase())
          .join('');

      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: FlowyText.semibold(
          nameInitials,
          color: Colors.white,
          fontSize: isLarge
              ? nameInitials.length == initialsCount
                  ? 20
                  : 26
              : nameInitials.length == initialsCount
                  ? 12
                  : 14,
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: Corners.s5Border,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: FlowySvg(
            FlowySvgData('emoji/$iconUrl'),
            blendMode: null,
          ),
        ),
      ),
    );
  }

  /// Return the user name, if the user name is empty,
  /// return the default user name.
  String _userName(String name) =>
      name.isEmpty ? LocaleKeys.defaultUsername.tr() : name;
}
