import { useGridTableItemHooks } from './GridTableItem.hooks';

export const GridTableItem = ({
  rowItem,
  rowId,
}: {
  rowItem: {
    fieldId: string;
    value: string;
    cellId: string;
  };
  rowId: string;
}) => {
  const { value, onValueChange, onValueBlur } = useGridTableItemHooks(rowItem, rowId);
  return (
    <div>
      <input
        className='w-full h-full rounded-lg p-3 border-2 border-transparent hover:border-main-accent'
        type='text'
        value={value}
        onChange={onValueChange}
        onBlur={onValueBlur}
      />
    </div>
  );
};
