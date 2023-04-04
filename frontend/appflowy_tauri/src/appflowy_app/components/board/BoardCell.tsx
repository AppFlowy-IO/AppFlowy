import { CellIdentifier } from '../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../stores/effects/database/field/field_controller';
import { FieldType } from '../../../services/backend';
import { BoardOptionsCell } from './BoardOptionsCell';
import { BoardDateCell } from './BoardDateCell';
import { BoardTextCell } from './BoardTextCell';
import { BoardUrlCell } from '$app/components/board/BoardUrlCell';

export const BoardCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  return (
    <>
      {cellIdentifier.fieldType === FieldType.SingleSelect ||
      cellIdentifier.fieldType === FieldType.MultiSelect ||
      cellIdentifier.fieldType === FieldType.Checklist ? (
        <BoardOptionsCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardOptionsCell>
      ) : cellIdentifier.fieldType === FieldType.DateTime ? (
        <BoardDateCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardDateCell>
      ) : cellIdentifier.fieldType === FieldType.URL ? (
        <BoardUrlCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardUrlCell>
      ) : (
        <BoardTextCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardTextCell>
      )}
    </>
  );
};
