import { GridTableCount } from '../GridTableCount/GridTableCount';
import { GridTableHeader } from '../GridTableHeader/GridTableHeader';
import { GridAddRow } from '../GridTableRows/GridAddRow';
import { GridTableRows } from '../GridTableRows/GridTableRows';
import { GridTitle } from '../GridTitle/GridTitle';
import { GridToolbar } from '../GridToolbar/GridToolbar';

export const Grid = ({ viewId }: { viewId: string }) => {
  return (
    <div className='mx-auto mt-8 flex flex-col gap-8 px-8'>
      <div className='flex w-full  items-center justify-between'>
        <GridTitle />
        <GridToolbar />
      </div>

      {/* table component view with text area for td */}
      <div className='flex flex-col gap-4'>
        <table className='w-full table-fixed text-sm'>
          <GridTableHeader />
          <GridTableRows />
        </table>

        <GridAddRow />
      </div>

      <GridTableCount />
    </div>
  );
};
