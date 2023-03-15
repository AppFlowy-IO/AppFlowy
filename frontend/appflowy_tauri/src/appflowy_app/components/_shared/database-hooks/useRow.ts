import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { RowController } from '$app/stores/effects/database/row/row_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useEffect, useState } from 'react';

export const useRow = (viewId: string, databaseController: DatabaseController, rowInfo: RowInfo) => {
  const [cells, setCells] = useState<{ fieldId: string; cellIdentifier: CellIdentifier }[]>([]);
  const [rowController, setRowController] = useState<RowController>();

  useEffect(() => {
    if (!databaseController || !rowInfo) return;
    const rowCache = databaseController.databaseViewCache.getRowCache();
    const fieldController = databaseController.fieldController;
    const c = new RowController(rowInfo, fieldController, rowCache);
    setRowController(c);

    return () => {
      // dispose row controller in future
    };
  }, [databaseController, rowInfo]);

  useEffect(() => {
    if (!rowController) return;

    void (async () => {
      const cellsPB = await rowController.loadCells();
      const loadingCells: { fieldId: string; cellIdentifier: CellIdentifier }[] = [];

      for (const [fieldId, cellIdentifier] of cellsPB.entries()) {
        loadingCells.push({
          fieldId,
          cellIdentifier,
        });
      }

      setCells(loadingCells);
    })();
  }, [rowController]);

  return {
    cells: cells,
  };
};
