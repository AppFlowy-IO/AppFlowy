import { useGridTitleHooks } from './GridTitle.hooks';
import { SettingsSvg } from '../../_shared/svg/SettingsSvg';
import { GridTitleOptionsPopup } from './GridTitleOptionsPopup';
import { useGridTitleOptionsPopupHooks } from './GridTitleOptionsPopup.hooks';
import { GridFilterPopup } from '../GridFilter/GridFilterPopup';
import { GridSortPopup } from '../GridSort/GridSortPopup';

export const GridTitle = () => {
  const { title, showOptions, setShowOptions } = useGridTitleHooks();

  const { showFilterPopup, setShowFilterPopup, setShowSortPopup, showSortPopup } = useGridTitleOptionsPopupHooks();

  return (
    <div className={'relative flex items-center '}>
      <div>{title}</div>

      <div className='flex '>
        <button className={'ml-2 h-5 w-5 '} onClick={() => setShowOptions(!showOptions)}>
          <SettingsSvg></SettingsSvg>
        </button>

        {showOptions && (
          <GridTitleOptionsPopup
            onClose={() => setShowOptions(!showOptions)}
            onFilterClick={() => {
              setShowFilterPopup(!showFilterPopup);
            }}
            onSortClick={() => {
              setShowSortPopup(!showSortPopup);
            }}
          />
        )}

        {showFilterPopup && (
          <GridFilterPopup
            onOutsideClick={() => {
              setShowFilterPopup(false);
            }}
          />
        )}

        {showSortPopup && (
          <GridSortPopup
            onOutsideClick={() => {
              setShowSortPopup(false);
            }}
          />
        )}
      </div>
    </div>
  );
};
