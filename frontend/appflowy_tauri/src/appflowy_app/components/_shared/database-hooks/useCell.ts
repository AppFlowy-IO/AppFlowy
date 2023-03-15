import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { CellControllerBuilder } from '$app/stores/effects/database/cell/controller_builder';
import { DateCellDataPB, SelectOptionCellDataPB, URLCellDataPB } from '$app/../services/backend';
import { useEffect, useState } from 'react';

export const useCell = (cellIdentifier: CellIdentifier, cellCache: CellCache, fieldController: FieldController) => {
  const [data, setData] = useState<DateCellDataPB | URLCellDataPB | SelectOptionCellDataPB | string | undefined>();

  useEffect(() => {
    if (!cellIdentifier || !cellCache || !fieldController) return;
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
      void cellController.dispose();
    };
  }, [cellIdentifier, cellCache, fieldController]);

  return {
    data,
  };
};
