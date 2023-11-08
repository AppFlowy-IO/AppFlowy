import { FC } from 'react';
import { GridTable } from '../GridTable';
import GridUIProvider from '$app/components/database/proxy/grid/ui_state/Provider';

export const Grid: FC<{ isActivated: boolean; tableHeight: number }> = ({ isActivated, tableHeight }) => {
  return (
    <GridUIProvider isActivated={isActivated}>
      <GridTable tableHeight={tableHeight} />
    </GridUIProvider>
  );
};
