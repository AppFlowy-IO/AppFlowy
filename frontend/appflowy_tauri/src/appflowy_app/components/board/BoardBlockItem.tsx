import { DatabaseFieldMap, IDatabaseColumn, IDatabaseRow } from '../../stores/reducers/database/slice';
import { Details2Svg } from '../_shared/svg/Details2Svg';
import { FieldType } from '../../../services/backend';
import { getBgColor } from '../_shared/getColor';

export const BoardBlockItem = ({
  groupingFieldId,
  fields,
  columns,
  row,
}: {
  groupingFieldId: string;
  fields: DatabaseFieldMap;
  columns: IDatabaseColumn[];
  row: IDatabaseRow;
}) => {
  return (
    <div
      className={'relative cursor-pointer rounded-lg border border-shade-6 bg-white px-3 py-2 hover:bg-main-selector'}
    >
      <button className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
        <Details2Svg></Details2Svg>
      </button>
      <div className={'flex flex-col gap-3'}>
        {columns
          .filter((column) => column.fieldId !== groupingFieldId)
          .map((column, index) => {
            switch (fields[column.fieldId].fieldType) {
              case FieldType.MultiSelect:
                return (
                  <div key={index} className={'flex flex-wrap items-center gap-2'}>
                    {row.cells[column.fieldId].optionIds?.map((option, indexOption) => {
                      const selectOptions = fields[column.fieldId].fieldOptions.selectOptions;
                      const selectedOption = selectOptions?.find((so) => so.selectOptionId === option);
                      return (
                        <div
                          key={indexOption}
                          className={`rounded px-1 py-0.5 text-sm ${getBgColor(selectedOption?.color)}`}
                        >
                          {selectedOption?.title}
                        </div>
                      );
                    })}
                  </div>
                );
              default:
                return <div key={index}>{row.cells[column.fieldId].data}</div>;
            }
          })}
      </div>
    </div>
  );
};
