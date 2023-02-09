import { Link } from 'react-router-dom';
import AddSvg from '../../_shared/AddSvg';

export const GridAddView = () => {
  return (
    <button className='flex items-center cursor-pointer text-sm p-2 rounded-lg hover:bg-main-selector'>
      <i className='w-5 h-5 mr-2'>
        <AddSvg />
      </i>
      <span>Add View</span>
    </button>
  );
};
