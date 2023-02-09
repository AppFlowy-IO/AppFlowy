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
              <th key={field.fieldId} className='border-l-0 border border-shade-6 m-0 p-0'>
                <div className={'flex items-center hover:bg-main-secondary p-2 cursor-pointer'}>
                  <i className={'w-5 h-5 mr-2 text-shade-3'}>
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

          <th className='border-r-0 border border-shade-6 m-0 p-0 w-40'>
            <div
              className='flex items-center text-shade-3 hover:text-black hover:bg-main-secondary p-2 cursor-pointer'
              onClick={onAddField}
            >
              <i className='w-5 h-5 mr-2'>
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
