import { Sort } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Sorts } from '../sort';

export const DatabaseCollection = () => {
  const { sorts } = useDatabase();

  const showSorts = sorts && sorts.length > 0;

  const showCollection = showSorts;

  return (
    <div className={`flex items-center ${!showCollection ? 'h-0' : 'border-b border-line-divider py-3'}`}>
      {showSorts && <Sorts sorts={sorts as Sort[]} />}
    </div>
  );
};
