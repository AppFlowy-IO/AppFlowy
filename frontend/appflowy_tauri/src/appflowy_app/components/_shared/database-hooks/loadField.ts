import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { IDatabaseField, ISelectOption } from '$app_reducers/database/slice';
import { ChecklistTypeOptionPB, FieldType, MultiSelectTypeOptionPB, SingleSelectTypeOptionPB } from '@/services/backend';
import {
  makeChecklistTypeOptionContext,
  makeDateTypeOptionContext,
  makeMultiSelectTypeOptionContext,
  makeNumberTypeOptionContext,
  makeSingleSelectTypeOptionContext,
} from '$app/stores/effects/database/field/type_option/type_option_context';
import { boardActions } from '$app_reducers/board/slice';
import { FieldInfo } from '$app/stores/effects/database/field/field_controller';
import { AppDispatch } from '$app/stores/store';

export default async function (viewId: string, fieldInfo: FieldInfo, dispatch?: AppDispatch): Promise<IDatabaseField> {
  const field = fieldInfo.field;
  const typeOptionController = new TypeOptionController(viewId, Some(fieldInfo));

  // temporary hack to set grouping field
  let groupingFieldSelected = false;

  switch (field.field_type) {
    case FieldType.SingleSelect:
    case FieldType.MultiSelect: {
      let selectOptions: ISelectOption[] = [];
      let typeOption: SingleSelectTypeOptionPB | MultiSelectTypeOptionPB | undefined;

      if (field.field_type === FieldType.SingleSelect) {
        typeOption = (await makeSingleSelectTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
        if (!groupingFieldSelected) {
          if (dispatch) {
            dispatch(boardActions.setGroupingFieldId({ fieldId: field.id }));
          }
          groupingFieldSelected = true;
        }
      }
      if (field.field_type === FieldType.MultiSelect) {
        typeOption = (await makeMultiSelectTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
      }

      if (typeOption) {
        selectOptions = typeOption.options.map<ISelectOption>((option) => {
          return {
            selectOptionId: option.id,
            title: option.name,
            color: option.color,
          };
        });
      }

      return {
        fieldId: field.id,
        title: field.name,
        fieldType: field.field_type,
        visible: field.visibility,
        fieldOptions: {
          selectOptions,
        },
      };
    }

    case FieldType.Number: {
      const typeOption = (await makeNumberTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
      return {
        fieldId: field.id,
        title: field.name,
        visible: field.visibility,
        fieldType: field.field_type,
        fieldOptions: {
          numberFormat: typeOption.format,
        },
      };
    }

    case FieldType.DateTime: {
      const typeOption = (await makeDateTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
      return {
        fieldId: field.id,
        title: field.name,
        visible: field.visibility,
        fieldType: field.field_type,
        fieldOptions: {
          dateFormat: typeOption.date_format,
          timeFormat: typeOption.time_format,
        },
      };
    }

    default: {
      return {
        fieldId: field.id,
        title: field.name,
        visible: field.visibility,
        fieldType: field.field_type,
      };
    }
  }
}
