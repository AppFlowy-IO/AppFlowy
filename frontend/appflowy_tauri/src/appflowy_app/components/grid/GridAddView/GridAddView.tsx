import { Link } from 'react-router-dom';
import AddSvg from '../../_shared/AddSvg';

export const GridAddView = () => {
  return (
    <div className='flex gap-4 items-center cursor-pointer '>
      <div className='flex shrink-0'>
        <span className='w-8 h-8 '>
          <AddSvg />
        </span>
        <button>
          <Link to='/'>Add View</Link>
        </button>
      </div>
    </div>
  );
};
