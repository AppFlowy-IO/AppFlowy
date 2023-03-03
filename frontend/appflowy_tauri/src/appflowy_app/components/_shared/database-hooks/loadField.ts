import { TypeOptionController } from '../../../stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { IDatabaseField, ISelectOption } from '../../../stores/reducers/database/slice';
import {
  ChecklistTypeOptionPB,
  DateFormat,
  FieldType,
  MultiSelectTypeOptionPB,
  NumberFormat,
  SingleSelectTypeOptionPB,
  TimeFormat,
} from '../../../../services/backend';
import {
  makeChecklistTypeOptionContext,
  makeDateTypeOptionContext,
  makeMultiSelectTypeOptionContext,
  makeNumberTypeOptionContext,
  makeSingleSelectTypeOptionContext,
} from '../../../stores/effects/database/field/type_option/type_option_context';
import { boardActions } from '../../../stores/reducers/board/slice';
import { FieldInfo } from '../../../stores/effects/database/field/field_controller';
import { AppDispatch } from '../../../stores/store';

export default async function (viewId: string, fieldInfo: FieldInfo, dispatch?: AppDispatch): Promise<IDatabaseField> {
  const field = fieldInfo.field;
  const typeOptionController = new TypeOptionController(viewId, Some(fieldInfo));

  let selectOptions: ISelectOption[] | undefined;
  let numberFormat: NumberFormat | undefined;
  let dateFormat: DateFormat | undefined;
  let timeFormat: TimeFormat | undefined;
  let includeTime: boolean | undefined;

  // temporary hack to set grouping field
  let groupingFieldSelected = false;

  switch (field.field_type) {
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
    case FieldType.Checklist:
      {
        let typeOption: SingleSelectTypeOptionPB | MultiSelectTypeOptionPB | ChecklistTypeOptionPB | undefined;

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
        if (field.field_type === FieldType.Checklist) {
          typeOption = (await makeChecklistTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
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
      }
      break;
    case FieldType.Number:
      {
        const typeOption = (await makeNumberTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
        numberFormat = typeOption.format;
      }
      break;
    case FieldType.DateTime:
      {
        const typeOption = (await makeDateTypeOptionContext(typeOptionController).getTypeOption()).unwrap();
        dateFormat = typeOption.date_format;
        timeFormat = typeOption.time_format;
        includeTime = typeOption.include_time;
      }
      break;
  }

  return {
    fieldId: field.id,
    title: field.name,
    fieldType: field.field_type,
    fieldOptions: {
      selectOptions,
      numberFormat,
      dateFormat,
      timeFormat,
      includeTime,
    },
  };
}
