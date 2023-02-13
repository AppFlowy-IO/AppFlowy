import AddSvg from '../../_shared/svg/AddSvg';
import { useGridAddRow } from './GridAddRow.hooks';
export const GridAddRow = () => {
  const { addRow } = useGridAddRow();

  return (
    <div>
      <button className='flex cursor-pointer items-center text-gray-500 hover:text-black' onClick={addRow}>
        <i className='mr-2 h-5 w-5'>
          <AddSvg />
        </i>
        <span>New row</span>
      </button>
    </div>
  );
};
