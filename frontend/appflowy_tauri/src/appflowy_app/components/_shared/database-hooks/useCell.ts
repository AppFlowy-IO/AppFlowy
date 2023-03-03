import { CellIdentifier } from '../../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../../stores/effects/database/field/field_controller';
import { CellControllerBuilder } from '../../../stores/effects/database/cell/controller_builder';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB } from '../../../../services/backend';
import { useState } from 'react';

export const useCell = (cellIdentifier: CellIdentifier, cellCache: CellCache, fieldController: FieldController) => {
  const [data, setData] = useState<string[]>([]);

  const loadCell = async () => {
    const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
    const cellController = builder.build();
    cellController.subscribeChanged({
      onCellChanged: (value) => {
        if (
          cellIdentifier.fieldType === FieldType.Checklist ||
          cellIdentifier.fieldType === FieldType.MultiSelect ||
          cellIdentifier.fieldType === FieldType.SingleSelect
        ) {
          const v = value.unwrap() as SelectOptionCellDataPB;
          setData(v.select_options.map((option) => option.id));
        } else if (cellIdentifier.fieldType === FieldType.DateTime) {
          const v = value.unwrap() as DateCellDataPB;
          setData([v.date]);
        } else {
          const v = value.unwrap() as string;
          setData([v]);
        }
      },
    });

    cellController.getCellData();
  };

  return {
    loadCell,
    data,
  };
};
