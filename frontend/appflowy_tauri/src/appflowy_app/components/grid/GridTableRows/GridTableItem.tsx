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
        className='h-full w-full rounded-lg border border-transparent p-2 focus:border-main-accent'
        type='text'
        value={value}
        onChange={onValueChange}
        onBlur={onValueBlur}
      />
    </div>
  );
};
