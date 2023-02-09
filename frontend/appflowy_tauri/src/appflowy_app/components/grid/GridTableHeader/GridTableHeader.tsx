import AddSvg from '../../_shared/AddSvg';
import { useGridTableHeaderHooks } from './GridTableHeader.hooks';
import { TextTypeSvg } from '../../_shared/TextTypeSvg';
import { NumberTypeSvg } from '../../_shared/NumberTypeSvg';
import { DateTypeSvg } from '../../_shared/DateTypeSvg';
import { SingleSelectTypeSvg } from '../../_shared/SingleSelectTypeSvg';
import { MultiSelectTypeSvg } from '../../_shared/MultiSelectTypeSvg';
import { ChecklistTypeSvg } from '../../_shared/ChecklistTypeSvg';
import { UrlTypeSvg } from '../../_shared/UrlTypeSvg';

export const GridTableHeader = () => {
  const { fields, onAddField } = useGridTableHeaderHooks();

  return (
    <>
      <thead>
        <tr>
          {fields.map((field, i) => {
            return (
              <th key={field.fieldId} className='m-0 border border-l-0 border-shade-6 p-0'>
                <div className={'flex cursor-pointer items-center p-2 hover:bg-main-secondary'}>
                  <i className={'mr-2 h-5 w-5 text-shade-3'}>
                    {field.fieldType === 'text' && <TextTypeSvg></TextTypeSvg>}
                    {field.fieldType === 'number' && <NumberTypeSvg></NumberTypeSvg>}
                    {field.fieldType === 'date' && <DateTypeSvg></DateTypeSvg>}
                    {field.fieldType === 'select' && <SingleSelectTypeSvg></SingleSelectTypeSvg>}
                    {field.fieldType === 'multiselect' && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
                    {field.fieldType === 'checklist' && <ChecklistTypeSvg></ChecklistTypeSvg>}
                    {field.fieldType === 'url' && <UrlTypeSvg></UrlTypeSvg>}
                  </i>
                  <span>{field.name}</span>
                </div>
              </th>
            );
          })}

          <th className='m-0 w-40 border border-r-0 border-shade-6 p-0'>
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
      </thead>
    </>
  );
};
