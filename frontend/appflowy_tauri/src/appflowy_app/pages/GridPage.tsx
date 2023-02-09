import { GridAddView } from '../components/grid/GridAddView/GridAddView';
import { GridTableCount } from '../components/grid/GridTableCount/GridTableCount';
import { GridTableHeader } from '../components/grid/GridTableHeader/GridTableHeader';
import { GridAddRow } from '../components/grid/GridTableRows/GridAddRow';
import { GridTableRows } from '../components/grid/GridTableRows/GridTableRows';
import { GridTitle } from '../components/grid/GridTitle/GridTitle';
import { SearchInput } from '../components/_shared/SearchInput';
import { GridToolbar } from '../components/grid/GridToolbar/GridToolbar';

export const GridPage = () => {
  return (
    <div className='mx-auto mt-8 flex flex-col gap-8 px-8'>
      <h1 className='text-4xl font-bold'>Grid</h1>

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
