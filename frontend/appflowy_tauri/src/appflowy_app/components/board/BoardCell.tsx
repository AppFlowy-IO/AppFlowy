import { useCell } from '../_shared/database-hooks/useCell';
import { CellIdentifier } from '../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../stores/effects/database/field/field_controller';
import { useEffect } from 'react';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB } from '../../../services/backend';
import { BoardOptionsCell } from './BoardOptionsCell';
import { BoardDateCell } from './BoardDateCell';
import { BoardTextCell } from './BoardTextCell';

export const BoardCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { loadCell, data } = useCell(cellIdentifier, cellCache, fieldController);
  useEffect(() => {
    void (async () => {
      await loadCell();
    })();
  }, []);

  return (
    <>
      {cellIdentifier.fieldType === FieldType.SingleSelect ||
      cellIdentifier.fieldType === FieldType.MultiSelect ||
      cellIdentifier.fieldType === FieldType.Checklist ? (
        <BoardOptionsCell value={data as SelectOptionCellDataPB | undefined}></BoardOptionsCell>
      ) : cellIdentifier.fieldType === FieldType.DateTime ? (
        <BoardDateCell value={data as DateCellDataPB | undefined}></BoardDateCell>
      ) : (
        <BoardTextCell value={data as string | undefined}></BoardTextCell>
      )}
    </>
  );
};
