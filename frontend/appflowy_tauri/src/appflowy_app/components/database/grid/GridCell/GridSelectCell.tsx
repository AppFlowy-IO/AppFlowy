import { FC } from 'react';
import { Database } from '$app/interfaces/database';

export const GridSelectCell: FC<{
  viewId: string;
  rowId: string;
  field: Database.Field;
  cell: Database.SelectCell | null;
}> = () => {
  return null;
}