import { useGridTableItemHooks } from './GridTableItem.hooks';

export const GridTableItem = ({
  rowItem,
  rowId,
}: {
  rowItem: {
    fieldId: string;
    value: string | number;
    cellId: string;
  };
  rowId: string;
}) => {
  const { value, onValueChange, onValueBlur } = useGridTableItemHooks(rowItem, rowId);
  return (
    <div>
      <input
        className='w-full h-full rounded-lg p-2 border border-transparent hover:border-main-accent'
        type='text'
        value={value}
        onChange={onValueChange}
        onBlur={onValueBlur}
      />
    </div>
  );
};
