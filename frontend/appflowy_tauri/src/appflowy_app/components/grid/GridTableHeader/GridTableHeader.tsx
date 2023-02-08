import AddSvg from '../../_shared/AddSvg';
import { useGridTableHeaderHooks } from './GridTableHeader.hooks';

export const GridTableHeader = () => {
  const { fields, onAddField } = useGridTableHeaderHooks();

  return (
    <>
      <thead>
        <tr>
          {fields.map((field, i) => {
            return (
              <th key={field.fieldId} className='border-l-0 border-2  border-slate-100  p-4  '>
                {field.name}
              </th>
            );
          })}

          <th className='border-r-0 border-2  border-slate-100  p-4  '>
            <button className='flex items-center cursor-pointer text-gray-500 hover:text-black' onClick={onAddField}>
              <span className='w-8 h-8'>
                <AddSvg />
              </span>
              New column
            </button>
          </th>
        </tr>
      </thead>
    </>
  );
};
