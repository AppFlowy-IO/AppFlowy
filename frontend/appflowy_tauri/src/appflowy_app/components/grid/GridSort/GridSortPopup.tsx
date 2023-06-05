import { t } from 'i18next';
import { PopupWindow } from '../../_shared/PopupWindow';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { useGridSortPopup } from './GridSortPopup.hooks';
import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';
import { MoreSvg } from '../../_shared/svg/MoreSvg';
import { DragSvg } from '../../_shared/svg/DragSvg';
import { CloseSvg } from '../../_shared/svg/CloseSvg';

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
          {sortRules.map((filter: any, i: number) => (
            <div className='flex  items-center justify-between gap-4  p-6'>
              <div>
                <div className='h-5 w-5'>
                  <DragSvg />
                </div>
              </div>

              <div className='w-64 rounded-lg border border-gray-300 p-2 '>
                <select
                  name='fields'
                  className='w-full appearance-none'
                  value={filter.fieldId}
                  onChange={(e) => {
                    onSortRuleFieldChange(i, e.target.value);
                  }}
                >
                  {fields.map((field) => (
                    <option value={field.fieldId}>{field.name}</option>
                  ))}
                </select>
              </div>

              <div className='w-64 rounded-lg border border-gray-300 p-2'>
                <select name='fields' className='w-full appearance-none' value={filter.operator}>
                  <option value='asc'>Ascending</option>
                  <option value='desc'>Descending</option>
                </select>
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
