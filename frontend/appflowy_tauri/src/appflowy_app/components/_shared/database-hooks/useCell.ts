import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { CellControllerBuilder } from '$app/stores/effects/database/cell/controller_builder';
import { DateCellDataPB, SelectOptionCellDataPB, URLCellDataPB } from '$app/../services/backend';
import { useEffect, useState } from 'react';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';

export const useCell = (cellIdentifier: CellIdentifier, cellCache: CellCache, fieldController: FieldController) => {
  const [data, setData] = useState<DateCellDataPB | URLCellDataPB | SelectOptionCellDataPB | string | undefined>();
  const [cellController, setCellController] = useState<CellController<any, any>>();

  useEffect(() => {
    if (!cellIdentifier || !cellCache || !fieldController) return;
    const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
    const c = builder.build();
    setCellController(c);

    c.subscribeChanged({
      onCellChanged: (cellData) => {
        if (cellData.some) {
          setData(cellData.val);
        }
      },
    });

    void (async () => {
      const cellData = await c.getCellData();
      if (cellData.some) {
        setData(cellData.unwrap());
      }
    })();

    return () => {
      void c.dispose();
    };
  }, [cellIdentifier, cellCache, fieldController]);

  return {
    cellController,
    data,
  };
};
