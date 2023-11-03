import { Sort } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Sorts } from '../sort';

export const DatabaseSettings = () => {
  const { sorts } = useDatabase();

  return (
    <div className="flex items-center border-t">
      <Sorts sorts={sorts as Sort[]} />
    </div>
  );
};
