import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/type_option_widget_builder/type_option_widget_builder.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/field/field_type_option_edit_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'mobile_field_type_list.dart';

class MobileFieldTypeOptionEditor extends StatelessWidget {
  final TypeOptionController _dataController;

  const MobileFieldTypeOptionEditor({
    required TypeOptionController dataController,
    Key? key,
  })  : _dataController = dataController,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = FieldTypeOptionEditBloc(_dataController);
        bloc.add(const FieldTypeOptionEditEvent.initial());
        return bloc;
      },
      child: BlocBuilder<FieldTypeOptionEditBloc, FieldTypeOptionEditState>(
        builder: (context, state) {
          final typeOptionWidget = _makeMobileTypeOptionWidget(
            context: context,
            dataController: _dataController,
          );

          return Column(
            children: [
              const _MobileSwitchFieldButton(),
              const VSpace(8),
              if (typeOptionWidget != null) typeOptionWidget
            ],
          );
        },
      ),
    );
  }
}

class _MobileSwitchFieldButton extends StatelessWidget {
  const _MobileSwitchFieldButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fieldType = context.select(
      (FieldTypeOptionEditBloc bloc) => bloc.state.field.fieldType,
    );
    return GestureDetector(
      child: Row(
        children: [
          Text(
            LocaleKeys.grid_field_propertyType.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          FlowySvg(fieldType.icon()),
          const HSpace(4),
          Text(
            fieldType.title(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Icon(
            Icons.arrow_forward_ios_sharp,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
      onTap: () => showFlowyMobileBottomSheet(
        context,
        isScrollControlled: true,
        title: LocaleKeys.grid_field_propertyType.tr(),
        builder: (_) => MobileFieldTypeList(
          bloc: context.read<FieldTypeOptionEditBloc>(),
          onSelectField: (newFieldType) {
            context.read<FieldTypeOptionEditBloc>().add(
                  FieldTypeOptionEditEvent.switchToField(newFieldType),
                );
            context.pop();
          },
        ),
      ),
    );
  }
}

Widget? _makeMobileTypeOptionWidget({
  required BuildContext context,
  required TypeOptionController dataController,
}) {
  final builder = _makeMobileTypeOptionMobileWidgetBuilder(
    dataController: dataController,
  );
  return builder.build(context);
}

TypeOptionWidgetBuilder _makeMobileTypeOptionMobileWidgetBuilder({
  required TypeOptionController dataController,
}) {
  final viewId = dataController.loader.viewId;
  final fieldType = dataController.field.fieldType;

  switch (dataController.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<CheckboxTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.DateTime:
      return DateTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<DateTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return TimestampTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<TimestampTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<SingleSelectTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<MultiSelectTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.Number:
      return NumberTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<NumberTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.RichText:
      return RichTextTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<RichTextTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.URL:
      return URLTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<URLTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.Checklist:
      return ChecklistTypeOptionMobileWidgetBuilder(
        makeTypeOptionContextWithDataController<ChecklistTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
  }
  throw UnimplementedError;
}
