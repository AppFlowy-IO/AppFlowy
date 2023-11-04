import { Sort } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Sorts } from '../sort';

export const DatabaseCollection = () => {
  const { sorts } = useDatabase();

  return (
    <div className='flex items-center border-t py-3'>
      <Sorts sorts={sorts as Sort[]} />
    </div>
  );
};
