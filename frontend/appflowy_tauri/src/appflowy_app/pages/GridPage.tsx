import { GridAddView } from '../components/grid/GridAddView/GridAddView';
import { GridTableCount } from '../components/grid/GridTableCount/GridTableCount';
import { GridTableHeader } from '../components/grid/GridTableHeader/GridTableHeader';
import { GridAddRow } from '../components/grid/GridTableRows/GridAddRow';
import { GridTableRows } from '../components/grid/GridTableRows/GridTableRows';
import { GridTitle } from '../components/grid/GridTitle/GridTitle';
import { SearchInput } from '../components/_shared/SearchInput';

export const GridPage = () => {
  return (
    <div className='flex flex-col gap-8 mt-24 mx-auto  w-[calc(100%-200px)]'>
      <h1 className='text-4xl font-bold'>Grid</h1>

      <div className='flex justify-between  w-full items-center'>
        <GridTitle />
        <div className='flex items-center gap-4 shrink-0'>
          <GridAddView />
          <SearchInput />
        </div>
      </div>

      {/* table component view with text area for td */}
      <div className='flex flex-col gap-4'>
        <table className=' w-full table-fixed'>
          <GridTableHeader />
          <GridTableRows />
        </table>

        <GridAddRow />
      </div>

      <GridTableCount />
    </div>
  );
};
