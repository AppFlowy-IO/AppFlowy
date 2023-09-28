import { FC, useMemo } from 'react';
import { Database } from '$app/interfaces/database';
import { FieldType } from '@/services/backend';

import { GridTextCell } from './GridTextCell';
import { GridNotSupportedCell } from './GridNotSupportedCell';
import { GridSelectCell } from './GridSelectCell';
import { useCell } from './GridCell.hooks';
import { GridCheckboxCell } from './GridCheckboxCell';

interface GridCellProps {
  rowId: string;
  field: Database.Field;
}

export const GridCell: FC<GridCellProps> = ({
  rowId,
  field,
}) => {
  const cell = useCell(rowId, field.id, field.type);

  const RenderCell = useMemo(() => {
    switch (field.type) {
      case FieldType.RichText:
        return GridTextCell;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return GridSelectCell;
      case FieldType.Checkbox:
        return GridCheckboxCell;
      default:
        return GridNotSupportedCell;
    }
  }, [field.type]);

  // TODO: find a better way to check cell type.
  return <RenderCell rowId={rowId} field={field} cell={cell as any} />;
};
