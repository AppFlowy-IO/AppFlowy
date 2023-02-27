import { useGridTableCellHooks } from './GridTableCell.hooks';

export const GridTableCell = ({ props }: { props: any }) => {
  const { onValueChange, onValueBlur, value } = useGridTableCellHooks(props);

  return (
    <div className='hover:border-1'>
      <input
        className='h-full w-full rounded-lg p-2 '
        type='text'
        value={value}
        onChange={onValueChange}
        onBlur={onValueBlur}
      />
    </div>
  );
};
