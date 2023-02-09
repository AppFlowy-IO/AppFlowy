import { GridTableItem } from './GridTableItem';
import { useGridTableRowsHooks } from './GridTableRows.hooks';

export const GridTableRows = () => {
  const { rows } = useGridTableRowsHooks();
  return (
    <tbody>
      {rows.map((row, i) => {
        return (
          <tr key={row.rowId}>
            {row.values.map((value) => {
              return (
                <td key={value.fieldId} className='border-l-0 border border-shade-6 p-0 m-0'>
                  <GridTableItem rowItem={value} rowId={row.rowId} />
                </td>
              );
            })}

            <td className='border-r-0 border border-shade-6 p-0 m-0'></td>
          </tr>
        );
      })}
    </tbody>
  );
};
