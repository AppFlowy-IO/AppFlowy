import { CellIdentifier } from '../../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../../stores/effects/database/field/field_controller';
import { CellControllerBuilder } from '../../../stores/effects/database/cell/controller_builder';
import { DateCellDataPB, SelectOptionCellDataPB, URLCellDataPB } from '../../../../services/backend';
import { useEffect, useState } from 'react';

export const useCell = (cellIdentifier: CellIdentifier, cellCache: CellCache, fieldController: FieldController) => {
  const [data, setData] = useState<DateCellDataPB | URLCellDataPB | SelectOptionCellDataPB | string | undefined>();

  useEffect(() => {
    const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
    const cellController = builder.build();
    cellController.subscribeChanged({
      onCellChanged: (value) => {
        setData(value.unwrap());
      },
    });

    // ignore the return value, because we are using the subscription
    void cellController.getCellData();

    return () => {
      // dispose is causing an error
      // void cellController.dispose();
    };
  }, []);

  return {
    data,
  };
};
