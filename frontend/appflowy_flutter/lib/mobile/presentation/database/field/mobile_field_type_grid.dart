import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'mobile_field_type_option_editor.dart';

const _supportedFieldTypes = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.URL,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.DateTime,
  FieldType.LastEditedTime,
  FieldType.CreatedTime,
  FieldType.Checkbox,
  FieldType.Checklist,
];

class MobileFieldTypeGrid extends StatelessWidget {
  const MobileFieldTypeGrid({
    super.key,
    required this.mode,
    required this.onSelectFieldType,
    this.scrollController,
  });

  final FieldOptionMode mode;
  final void Function(FieldType) onSelectFieldType;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DragHandler(),
          _FieldHeader(mode: mode),
          const Divider(height: 0.5, thickness: 0.5),
          const VSpace(18.0),
          _GridView(
            crossAxisCount: 3,
            verticalSpacing: 18,
            children: _supportedFieldTypes
                .map(
                  (e) => _Field(
                    type: e,
                    onTap: () => onSelectFieldType(e),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({required this.mode});

  final FieldOptionMode mode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AppBarCloseButton(),
          ),
          Align(
            child: FlowyText.medium(
              switch (mode) {
                FieldOptionMode.add => LocaleKeys.grid_field_newProperty.tr(),
                FieldOptionMode.edit => LocaleKeys.grid_field_editProperty.tr(),
              },
              fontSize: 17.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.type,
    required this.onTap,
  });

  final FieldType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: constraints.maxWidth * 0.75,
                width: constraints.maxWidth * 0.75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: type.mobileIconBackgroundColor,
                ),
                child: Center(
                  child: FlowySvg(
                    type.svgData,
                    blendMode: null,
                    size: const Size.square(35),
                  ),
                ),
              ),
              const VSpace(6.0),
              Stack(
                children: [
                  FlowyText(
                    type.i18n,
                    fontSize: 15.0,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const FlowyText(
                    "\n\n",
                    fontSize: 15.0,
                    maxLines: 2,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView({
    required this.children,
    required this.crossAxisCount,
    required this.verticalSpacing,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double verticalSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(bottom: verticalSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Flexible(
                  flex: 6,
                  fit: FlexFit.tight,
                  child: children[i],
                ),
                const Spacer(flex: 2),
                Flexible(
                  flex: 6,
                  fit: FlexFit.tight,
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
                const Spacer(flex: 2),
                Flexible(
                  flex: 6,
                  fit: FlexFit.tight,
                  child: i + 2 < children.length
                      ? children[i + 2]
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
              ],
            ),
          ),
      ],
    );
  }
}
