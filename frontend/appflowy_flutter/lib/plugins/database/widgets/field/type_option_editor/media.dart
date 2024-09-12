import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/builder.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:protobuf/protobuf.dart';

class MediaTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const MediaTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: GridSize.popoverItemHeight,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: FlowyButton(
                  resetHoverOnRebuild: false,
                  text: FlowyText.medium(
                    LocaleKeys.grid_media_hideFileNames.tr(),
                    lineHeight: 1.0,
                  ),
                  rightIcon: Toggle(
                    value: typeOption.hideFileNames,
                    onChanged: (value) {
                      onTypeOptionUpdated(
                        _toggleHideFiles(typeOption, !value).writeToBuffer(),
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  MediaTypeOptionPB _parseTypeOptionData(List<int> data) {
    return MediaTypeOptionDataParser().fromBuffer(data);
  }

  MediaTypeOptionPB _toggleHideFiles(
    MediaTypeOptionPB typeOption,
    bool hideFileNames,
  ) {
    typeOption.freeze();
    return typeOption
        .rebuild((typeOption) => typeOption.hideFileNames = hideFileNames);
  }
}
