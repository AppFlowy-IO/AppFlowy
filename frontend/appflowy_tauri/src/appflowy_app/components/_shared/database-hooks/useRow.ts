import { DatabaseController } from '../../../stores/effects/database/database_controller';
import { RowController } from '../../../stores/effects/database/row/row_controller';
import { RowInfo } from '../../../stores/effects/database/row/row_cache';
import { CellIdentifier } from '../../../stores/effects/database/cell/cell_bd_svc';
import { useState } from 'react';

export const useRow = (viewId: string, databaseController: DatabaseController, rowInfo: RowInfo) => {
  const [cells, setCells] = useState<{ fieldId: string; cellIdentifier: CellIdentifier }[]>([]);

  const rowCache = databaseController.databaseViewCache.getRowCache();
  const fieldController = databaseController.fieldController;
  const rowController = new RowController(rowInfo, fieldController, rowCache);

  const loadRow = async () => {
    const cellsPB = await rowController.loadCells();
    const loadingCells: { fieldId: string; cellIdentifier: CellIdentifier }[] = [];

    for (const [fieldId, cellIdentifier] of cellsPB.entries()) {
      loadingCells.push({
        fieldId,
        cellIdentifier,
      });
    }

    setCells(loadingCells);
  };

  return {
    loadRow: loadRow,
    cells: cells,
  };
};
