import { t } from 'i18next';
import { PopupWindow } from '../../_shared/PopupWindow';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { useGridFilterPopup } from './GridFilterPopup.hooks';
import { Select } from '../../_shared/Select';
import { FieldTypeIcon } from '../../_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '../../_shared/EditRow/FieldTypeName';
import { GridFilterValue } from './GridFilterValue';

export const GridFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const { fields, addFilter, filters, onFieldChange } = useGridFilterPopup();

  return (
    <PopupWindow className={' w-[1020px] overflow-y-auto bg-white'} onOutsideClick={onOutsideClick} left={500} top={250}>
      <div className='flex w-full flex-col '>
        <div className='p-6'>{t('grid.settings.filter')}</div>

        <div className='max-h-48 overflow-y-scroll'>
          {filters.map((filter, i: number) => (
            <div className='flex  items-center  gap-4  p-6' key={i}>
              <div>
                {i === 0 ? (
                  <span>Where</span>
                ) : (
                  <div className='rounded-lg border border-gray-300'>
                    <Select
                      options={[
                        {
                          name: 'And',
                          value: 'and',
                        },
                        {
                          name: 'Or',
                          value: 'or',
                        },
                      ]}
                      value='and'
                      setValue={(value) => {
                        console.log(value);
                      }}
                      dropdownClassName='w-20'
                    />
                  </div>
                )}
              </div>

              <div className='w-64 rounded-lg border border-gray-300  '>
                <Select
                  options={fields.map((field) => ({
                    name: field.name,
                    value: field.fieldId,
                    icon: <FieldTypeIcon fieldType={field.fieldType} />,
                  }))}
                  setValue={(value) => {
                    console.log({ value });
                    onFieldChange(i, value);
                  }}
                  value={filter.fieldId}
                  dropdownClassName='w-64'
                />
              </div>

              <div className='w-64 rounded-lg border border-gray-300 '>
                <Select
                  options={[
                    { name: 'contains', value: 'contains' },
                    { name: 'is', value: 'is' },
                    { name: 'is not', value: 'is not' },
                    { name: 'is empty', value: 'is empty' },
                    { name: 'is not empty', value: 'is not empty' },
                  ]}
                  setValue={(value) => {
                    console.log(value);
                  }}
                  value={filter.operator}
                  dropdownClassName='w-64'
                />
              </div>

              <div className='w-64 rounded-lg border border-gray-300  '>
                <GridFilterValue
                  fieldType={fields.find((field) => field.fieldId === filter.fieldId)?.fieldType ?? 0}
                  fieldId={filter.fieldId}
                  value={filter.value}
                />
              </div>

              <div className='w-5'>
                <button>
                  <Details2Svg />
                </button>
              </div>
            </div>
          ))}
        </div>

        <hr />

        <button className='flex cursor-pointer items-center gap-2 p-4' onClick={addFilter}>
          <div className='h-5 w-5'>
            <AddSvg />
          </div>
          {t('grid.settings.addFilter')}
        </button>
      </div>
    </PopupWindow>
  );
};
