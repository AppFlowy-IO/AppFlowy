import { t } from 'i18next';
import { PopupWindow } from '../../_shared/PopupWindow';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { useGridSortPopup } from './GridSortPopup.hooks';
import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';
import { MoreSvg } from '../../_shared/svg/MoreSvg';
import { DragSvg } from '../../_shared/svg/DragSvg';
import { CloseSvg } from '../../_shared/svg/CloseSvg';
import { Select } from '../../_shared/Select';
import { FieldTypeIcon } from '../../_shared/EditRow/FieldTypeIcon';

export const GridSortPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const { fields, sortRules, onSortRuleFieldChange, addSortRule } = useGridSortPopup();

  return (
    <PopupWindow className={' w-[720px] overflow-y-auto bg-white'} onOutsideClick={onOutsideClick} left={500} top={250}>
      <div className='flex w-full flex-col '>
        <div className='flex gap-2 p-6 text-gray-400'>
          {t('grid.settings.sortBy')} :{' '}
          <span className='flex cursor-pointer text-black'>
            Default
            <div className='h-5 w-5'>
              <MoreSvg />
            </div>
          </span>
        </div>

        <div className='max-h-48 overflow-y-auto'>
          {sortRules.map((rule: any, i: number) => (
            <div className='flex  items-center justify-between gap-4  p-6'>
              <div>
                <div className='h-5 w-5'>
                  <DragSvg />
                </div>
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
                    onSortRuleFieldChange(i, value);
                  }}
                  value={rule.fieldId}
                  dropdownClassName='w-64'
                />
              </div>

              <div className='w-64 rounded-lg border border-gray-300'>
                <Select
                  options={[
                    {
                      name: 'Ascending',
                      value: 'asc',
                    },
                    {
                      name: 'Descending',
                      value: 'desc',
                    },
                  ]}
                  setValue={(value) => {
                    console.log(value);
                  }}
                  value={'asc'}
                  dropdownClassName='w-64'
                />
              </div>

              <div className='w-5'>
                <button>
                  <CloseSvg />
                </button>
              </div>
            </div>
          ))}
        </div>

        <hr />

        <button className='flex cursor-pointer items-center gap-2 p-4' onClick={addSortRule}>
          <div className='h-5 w-5'>
            <AddSvg />
          </div>
          {t('grid.sort.addSort')}
        </button>
      </div>
    </PopupWindow>
  );
};
