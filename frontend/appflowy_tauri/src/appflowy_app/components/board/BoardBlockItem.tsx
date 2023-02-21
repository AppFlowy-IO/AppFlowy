import { IDatabaseColumn, IDatabaseRow } from '../../stores/reducers/database/slice';
import { Details2Svg } from '../_shared/svg/Details2Svg';

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
    <div className={'relative rounded-lg border border-shade-6 bg-white px-3 py-2'}>
      <button className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
        <Details2Svg></Details2Svg>
      </button>
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
