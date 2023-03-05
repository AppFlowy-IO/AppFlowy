import { flexRender, Table } from '@tanstack/react-table';
import { FieldType } from '../../../../services/backend';
import AddSvg from '../../_shared/svg/AddSvg';
import { ChecklistTypeSvg } from '../../_shared/svg/ChecklistTypeSvg';
import { DateTypeSvg } from '../../_shared/svg/DateTypeSvg';
import { MultiSelectTypeSvg } from '../../_shared/svg/MultiSelectTypeSvg';
import { NumberTypeSvg } from '../../_shared/svg/NumberTypeSvg';
import { SingleSelectTypeSvg } from '../../_shared/svg/SingleSelectTypeSvg';
import { TextTypeSvg } from '../../_shared/svg/TextTypeSvg';
import { UrlTypeSvg } from '../../_shared/svg/UrlTypeSvg';
import { GridTableHeaderHooks } from './GridTableHeader.hooks';

export const GridTableHeader = ({ table }: { table: Table<any> }) => {
  const { onAddField } = GridTableHeaderHooks();

  return (
    <thead>
      {table.getHeaderGroups().map((headerGroup) => (
        <tr key={headerGroup.id} className='relative flex min-w-fit  '>
          {headerGroup.headers.map((header) => (
            <th
              {...{
                key: header.id,
                colSpan: header.colSpan,
                style: {
                  width: header.getSize(),
                },
              }}
              className='relative m-0  border   border-shade-6'
            >
              <div className={' flex cursor-pointer items-center bg-white p-2 hover:bg-main-secondary'}>
                <i className={'mr-2 h-5 w-5 text-shade-3'}>
                  {header.column.columnDef.meta === FieldType.RichText && <TextTypeSvg></TextTypeSvg>}
                  {header.column.columnDef.meta === FieldType.Number && <NumberTypeSvg></NumberTypeSvg>}
                  {header.column.columnDef.meta === FieldType.DateTime && <DateTypeSvg></DateTypeSvg>}
                  {header.column.columnDef.meta === FieldType.SingleSelect && (
                    <SingleSelectTypeSvg></SingleSelectTypeSvg>
                  )}
                  {header.column.columnDef.meta === FieldType.MultiSelect && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
                  {header.column.columnDef.meta === FieldType.Checklist && <ChecklistTypeSvg></ChecklistTypeSvg>}
                  {header.column.columnDef.meta === FieldType.URL && <UrlTypeSvg></UrlTypeSvg>}
                </i>
                <span className=' group-hover:bg-main-secondary  '>
                  {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                </span>
              </div>

              <div
                {...{
                  onMouseDown: header.getResizeHandler(),
                  onTouchStart: header.getResizeHandler(),
                }}
                className='bg-main-primary absolute right-0 top-0 h-full w-1 cursor-col-resize  '
              />
            </th>
          ))}
          <th className='m-0 w-40 border  border-shade-6 p-0'>
            <div
              className='flex cursor-pointer items-center p-2 text-shade-3 hover:bg-main-secondary hover:text-black'
              onClick={onAddField}
            >
              <i className='mr-2 h-5 w-5'>
                <AddSvg />
              </i>
              <span>New column</span>
            </div>
          </th>
        </tr>
      ))}
    </thead>
  );
};
