import AddSvg from '../../_shared/AddSvg';
import { useGridAddRow } from './GridAddRow.hooks';
export const GridAddRow = () => {
  const { addRow } = useGridAddRow();

  return (
    <div>
      <button className='flex items-center cursor-pointer text-gray-500 hover:text-black' onClick={addRow}>
        <span className='w-8 h-8'>
          <AddSvg />
        </span>
        New row
      </button>
    </div>
  );
};
