import { GridAddView } from '../GridAddView/GridAddView';
import { SearchInput } from '../../_shared/SearchInput';
import { GridSortButton } from './GridSortButton';
import { GridFieldsButton } from './GridFieldsButton';
import { GridFilterButton } from './GridFilterButton';

export const GridToolbar = () => {
  return (
    <div className='flex shrink-0 items-center gap-4'>
      <SearchInput />
      <GridAddView />
      <GridFilterButton></GridFilterButton>
      <GridSortButton></GridSortButton>
      <GridFieldsButton></GridFieldsButton>
    </div>
  );
};
