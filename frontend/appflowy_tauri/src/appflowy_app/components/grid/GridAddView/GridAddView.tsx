import { Link } from 'react-router-dom';
import AddSvg from '../../_shared/svg/AddSvg';

export const GridAddView = () => {
  return (
    <button className='flex cursor-pointer items-center rounded-lg p-2 text-sm hover:bg-main-selector'>
      <i className='mr-2 h-5 w-5'>
        <AddSvg />
      </i>
      <span>Add View</span>
    </button>
  );
};
