import { FC } from 'react';
import { GridTable, GridTableProps } from './grid_table';

export const Grid: FC<GridTableProps> = (props) => {
  return <GridTable {...props} />;
};
