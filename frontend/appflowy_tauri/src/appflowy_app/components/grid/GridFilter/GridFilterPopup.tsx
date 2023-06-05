import { t } from 'i18next';
import { PopupWindow } from '../../_shared/PopupWindow';
import AddSvg from '../../_shared/svg/AddSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { useGridFilterPopup } from './GridFilterPopup.hooks';

export const GridFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const { fields, addFilter, filters, onFieldChange } = useGridFilterPopup();

  return (
    <PopupWindow className={' w-[1020px] overflow-y-auto bg-white'} onOutsideClick={onOutsideClick} left={500} top={250}>
      <div className='flex w-full flex-col '>
        <div className='p-6'>{t('grid.settings.filter')}</div>

        <div className='max-h-48 overflow-y-auto'>
          {filters.map((filter: any, i: number) => (
            <div className='flex  items-center justify-between gap-4  p-6'>
              <div>Where</div>

              <div className='w-64 rounded-lg border border-gray-300 p-2 '>
                <select
                  name='fields'
                  className='w-full appearance-none'
                  value={filter.fieldId}
                  onChange={(e) => {
                    onFieldChange(i, e.target.value);
                  }}
                >
                  {fields.map((field) => (
                    <option value={field.fieldId}>{field.name}</option>
                  ))}
                </select>
              </div>

              <div className='w-64 rounded-lg border border-gray-300 p-2'>
                <select name='fields' className='w-full appearance-none' value={filter.operator}>
                  <option value='contains'>contains</option>
                  <option value='contains'>contains</option>
                  <option value='contains'>contains</option>
                  <option value='contains'>contains</option>
                </select>
              </div>

              <div className='w-64 rounded-lg border border-gray-300 p-2'>
                <input value={filter.value} />
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
