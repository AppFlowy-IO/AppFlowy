import { GridTableHeader } from '../GridTableHeader/GridTableHeader';
import { GridTableRow } from '../GridTableRow/GridTableRow';
import { useGridTableHooks } from './GridTable.hooks';

export const GridTable = () => {
  const { table } = useGridTableHooks();

  return (
    <div className='max-w-[90rem] select-none overflow-x-scroll'>
      <table
        className='text-sm'
        {...{
          style: {
            width: table.getCenterTotalSize(),
          },
        }}
      >
        <GridTableHeader table={table} />

        <tbody>
          {table.getRowModel().rows.map((row) => (
            <GridTableRow row={row} />
          ))}
        </tbody>
      </table>
    </div>
  );
};
