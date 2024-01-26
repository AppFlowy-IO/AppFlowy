import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mobile_field_type_option_editor.dart';

const _supportedFieldTypes = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.URL,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.DateTime,
  FieldType.Checkbox,
  FieldType.Checklist,
  FieldType.LastEditedTime,
  FieldType.CreatedTime,
];

class FieldOptions extends StatelessWidget {
  const FieldOptions({
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
          _FieldHeader(mode: mode),
          const VSpace(12.0),
          _GridView(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            itemSize: const Size(82, 140),
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
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: AppBarCancelButton(
              onTap: () => context.pop(),
            ),
          ),
          FlowyText.medium(
            switch (mode) {
              FieldOptionMode.add => LocaleKeys.grid_field_newProperty.tr(),
              FieldOptionMode.edit => LocaleKeys.grid_field_editProperty.tr(),
            },
            fontSize: 17.0,
          ),
          const HSpace(120),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlowySvg(
            type.svgData,
            blendMode: null,
            size: const Size.square(82),
          ),
          const VSpace(6.0),
          FlowyText(
            type.i18n,
            fontSize: 15.0,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView({
    required this.children,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.itemSize,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final Size itemSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(bottom: mainAxisSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < crossAxisCount; j++)
                  i + j < children.length
                      ? ConstrainedBox(
                          constraints: BoxConstraints.tight(itemSize),
                          child: children[i + j],
                        )
                      : SizedBox.fromSize(size: itemSize),
              ],
            ),
          ),
      ],
    );
  }
}
