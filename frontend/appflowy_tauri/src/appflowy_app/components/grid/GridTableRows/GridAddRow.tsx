import AddSvg from '../../_shared/AddSvg';
import { useGridAddRow } from './GridAddRow.hooks';
export const GridAddRow = () => {
  const { addRow } = useGridAddRow();

  return (
    <div>
      <button className='flex items-center cursor-pointer text-gray-500 hover:text-black' onClick={addRow}>
        <i className='w-5 h-5 mr-2'>
          <AddSvg />
        </i>
        <span>New row</span>
      </button>
    </div>
  );
};
