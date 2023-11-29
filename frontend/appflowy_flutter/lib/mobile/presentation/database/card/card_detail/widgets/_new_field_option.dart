import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NewFieldOption extends StatefulWidget {
  const NewFieldOption({
    super.key,
    required this.type,
  });

  final FieldType type;

  @override
  State<NewFieldOption> createState() => _NewFieldOptionState();
}

class _NewFieldOptionState extends State<NewFieldOption> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.type.i18n;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ColoredDivider(),
        FlowyOptionTile.textField(
          controller: controller,
          textFieldPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          leftIcon: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FlowySvg(
              widget.type.svgData,
              size: const Size.square(36.0),
              blendMode: null,
            ),
          ),
        ),
        const _ColoredDivider(),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_propertyType.tr(),
          leading: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FlowyText(
                widget.type.i18n,
                color: Theme.of(context).hintColor,
                fontSize: 16.0,
              ),
              const HSpace(4.0),
              FlowySvg(
                FlowySvgs.arrow_right_s,
                color: Theme.of(context).hintColor,
                size: const Size.square(18.0),
              ),
            ],
          ),
        ),
        const _ColoredDivider(),
        const _ColoredDivider(),
      ],
    );
  }
}

class _ColoredDivider extends StatelessWidget {
  const _ColoredDivider();

  @override
  Widget build(BuildContext context) {
    return VSpace(
      24.0,
      color: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}
