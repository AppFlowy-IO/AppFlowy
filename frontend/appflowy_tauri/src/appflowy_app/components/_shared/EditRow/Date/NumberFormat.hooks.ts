import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { FieldType, NumberFormatPB } from '@/services/backend';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { makeNumberTypeOptionContext } from '$app/stores/effects/database/field/type_option/type_option_context';

export const useNumberFormat = (cellIdentifier: CellIdentifier, fieldController: FieldController) => {
  const changeNumberFormat = async (format: NumberFormatPB) => {
    const fieldInfo = fieldController.getField(cellIdentifier.fieldId);
    if (!fieldInfo) return;
    const typeOptionController = new TypeOptionController(cellIdentifier.viewId, Some(fieldInfo), FieldType.Number);
    await typeOptionController.initialize();
    const numberTypeOptionContext = makeNumberTypeOptionContext(typeOptionController);
    const typeOption = await numberTypeOptionContext.getTypeOption().then((a) => a.unwrap());
    typeOption.format = format;
    await numberTypeOptionContext.setTypeOption(typeOption);
  };

  return {
    changeNumberFormat,
  };
};
