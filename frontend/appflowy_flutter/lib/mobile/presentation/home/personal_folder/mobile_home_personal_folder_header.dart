import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobilePersonalFolderHeader extends StatefulWidget {
  const MobilePersonalFolderHeader({
    super.key,
    required this.onPressed,
    required this.onAdded,
    required this.isExpanded,
  });

  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final bool isExpanded;

  @override
  State<MobilePersonalFolderHeader> createState() =>
      _MobilePersonalFolderHeaderState();
}

class _MobilePersonalFolderHeaderState
    extends State<MobilePersonalFolderHeader> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    const iconSize = 32.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: FlowyButton(
            text: FlowyText.semibold(
              LocaleKeys.sideBar_personal.tr(),
              fontSize: 20.0,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            expandText: false,
            mainAxisAlignment: MainAxisAlignment.start,
            rightIcon: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _turns,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              setState(() {
                _turns = widget.isExpanded ? -0.25 : 0;
              });
              widget.onPressed();
            },
          ),
        ),
        FlowyIconButton(
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          iconPadding: const EdgeInsets.all(2),
          height: iconSize,
          width: iconSize,
          icon: const FlowySvg(
            FlowySvgs.add_s,
            size: Size.square(iconSize),
          ),
          onPressed: () {
            context.read<MenuBloc>().add(
                  MenuEvent.createApp(
                    LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                    index: 0,
                  ),
                );
          },
        ),
      ],
    );
  }
}
