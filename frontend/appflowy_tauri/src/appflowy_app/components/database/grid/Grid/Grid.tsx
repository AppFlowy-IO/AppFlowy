import { FC, RefObject } from 'react';
import { GridToolbar } from '../GridToolbar';
import { GridTable } from '../GridTable/GridTable';

export const Grid: FC<{ scrollElementRef: RefObject<HTMLElement> }> = ({
  scrollElementRef,
}) => {
  return (
    <>
     <GridToolbar />
     <GridTable scrollElementRef={scrollElementRef} />
    </>
  );
};