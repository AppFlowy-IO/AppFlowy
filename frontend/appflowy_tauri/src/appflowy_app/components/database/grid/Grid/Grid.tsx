import { FC } from 'react';
import { GridTable, GridTableProps } from '../GridTable';

export const Grid: FC<GridTableProps> = (props) => {
  return <GridTable {...props} />;
};
