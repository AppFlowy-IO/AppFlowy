import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { DateFormatPB, DateTypeOptionPB, FieldType, TimeFormatPB } from '@/services/backend';
import { makeDateTypeOptionContext } from '$app/stores/effects/database/field/type_option/type_option_context';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';

export const useDateTimeFormat = (cellIdentifier: CellIdentifier, fieldController: FieldController) => {
  const changeFormat = async (change: (option: DateTypeOptionPB) => void) => {
    const fieldInfo = fieldController.getField(cellIdentifier.fieldId);
    if (!fieldInfo) return;
    const typeOptionController = new TypeOptionController(cellIdentifier.viewId, Some(fieldInfo), FieldType.DateTime);
    await typeOptionController.initialize();
    const dateTypeOptionContext = makeDateTypeOptionContext(typeOptionController);
    const typeOption = await dateTypeOptionContext.getTypeOption().then((a) => a.unwrap());
    change(typeOption);
    await dateTypeOptionContext.setTypeOption(typeOption);
  };

  const changeDateFormat = async (format: DateFormatPB) => {
    await changeFormat((option) => (option.date_format = format));
  };
  const changeTimeFormat = async (format: TimeFormatPB) => {
    await changeFormat((option) => (option.time_format = format));
  };
  const includeTime = async (include: boolean) => {
    await changeFormat((option) => {
      // option.include_time = include;
    });
  };

  return {
    changeDateFormat,
    changeTimeFormat,
    includeTime,
  };
};
