import { flexRender, Row } from '@tanstack/react-table';

export const GridTableRow = ({ row }: { row: Row<any> }) => {
  return (
    <tr key={row.id} className='flex'>
      {row.getVisibleCells().map((cell) => (
        <td
          {...{
            key: cell.id,
            style: {
              width: cell.column.getSize(),
            },
          }}
          className='m-0   border border-shade-6  p-0 focus-within:border-main-accent	'
        >
          {flexRender(cell.column.columnDef.cell, { ...cell.getContext(), row: row.original })}
        </td>
      ))}
    </tr>
  );
};
