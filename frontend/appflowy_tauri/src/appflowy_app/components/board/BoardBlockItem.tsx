import { IDatabaseColumn, IDatabaseRow } from '../../stores/reducers/database/slice';

export const BoardBlockItem = ({
  groupingFieldId,
  columns,
  row,
}: {
  groupingFieldId: string;
  columns: IDatabaseColumn[];
  row: IDatabaseRow;
}) => {
  return (
    <div className={'rounded-lg border border-shade-6 bg-white px-3 py-2'}>
      <div className={'flex flex-col gap-2'}>
        {columns
          .filter((column) => column.fieldId !== groupingFieldId)
          .map((column, index) => (
            <div key={index}>{row.cells[column.fieldId].data}</div>
          ))}
      </div>
    </div>
  );
};
