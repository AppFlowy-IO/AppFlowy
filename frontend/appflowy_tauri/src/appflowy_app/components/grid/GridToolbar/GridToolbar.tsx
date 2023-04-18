import { GridAddView } from '../GridAddView/GridAddView';
import { SearchInput } from '../../_shared/SearchInput';

export const GridToolbar = () => {
  return (
    <div className='flex shrink-0 items-center gap-4'>
      <SearchInput />
      <GridAddView />
    </div>
  );
};
