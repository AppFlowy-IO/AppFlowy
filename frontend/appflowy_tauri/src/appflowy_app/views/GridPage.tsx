import { GridTableCount } from '../components/grid/GridTableCount/GridTableCount';

import { GridAddRow } from '../components/grid/GridAddRow/GridAddRow';

import { GridTitle } from '../components/grid/GridTitle/GridTitle';

import { GridToolbar } from '../components/grid/GridToolbar/GridToolbar';
import { useParams } from 'react-router-dom';
import { useGrid } from './GridPage.hooks';
import { useEffect } from 'react';
import { GridTable } from '../components/grid/GridTable/GridTable';

export const GridPage = () => {
  const params = useParams();
  const { loadGrid } = useGrid();
  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      await loadGrid(params.id);
    })();
  }, [params]);

  return (
    <div className='mx-auto mt-8 flex flex-col gap-8 px-8'>
      <h1 className='text-4xl font-bold'>Grid</h1>

      <div className='flex w-full  items-center justify-between'>
        <GridTitle />
        <GridToolbar />
      </div>

      {/* table component view with text area for td */}
      <div className='flex flex-col gap-4'>
        <GridTable />

        <GridAddRow />
      </div>

      <GridTableCount />
    </div>
  );
};
