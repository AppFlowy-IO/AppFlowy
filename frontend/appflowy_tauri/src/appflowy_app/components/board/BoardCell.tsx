import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { FieldType } from '@/services/backend';
import { BoardOptionsCell } from './BoardOptionsCell';
import { BoardDateCell } from './BoardDateCell';
import { BoardTextCell } from './BoardTextCell';
import { BoardUrlCell } from '$app/components/board/BoardUrlCell';
import { BoardCheckboxCell } from '$app/components/board/BoardCheckboxCell';
import { BoardCheckListCell } from '$app/components/board/BoardCheckListCell';

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
      {cellIdentifier.fieldType === FieldType.SingleSelect || cellIdentifier.fieldType === FieldType.MultiSelect ? (
        <BoardOptionsCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardOptionsCell>
      ) : cellIdentifier.fieldType === FieldType.Checklist ? (
        <BoardCheckListCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardCheckListCell>
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
      ) : cellIdentifier.fieldType === FieldType.Checkbox ? (
        <BoardCheckboxCell
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        ></BoardCheckboxCell>
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
