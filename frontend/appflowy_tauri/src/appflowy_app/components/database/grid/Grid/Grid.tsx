import { FC } from 'react';
import { GridToolbar } from '../GridToolbar';
import { GridTable } from '../GridTable/GridTable';

export const Grid: FC = () => {
  return (
    <>
     <GridToolbar />
     <GridTable />
    </>
  );
};