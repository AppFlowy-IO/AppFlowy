import { SettingsSvg } from '../../_shared/svg/SettingsSvg';
import { GridTitleOptionsPopup } from './GridTitleOptionsPopup';
import { useState } from 'react';
import { useAppSelector } from '$app/stores/store';

export const GridTitle = ({
  onShowFilterClick,
  onShowSortClick,
  viewId,
}: {
  onShowFilterClick: () => void;
  onShowSortClick: () => void;
  viewId: string;
}) => {
  const [showOptions, setShowOptions] = useState(false);
  const pagesStore = useAppSelector((state) => state.pages.pageMap[viewId]);

  return (
    <div className={'relative flex items-center '}>
      <div className='flex '>
        <div>{pagesStore?.name}</div>
        <button className={'ml-2 h-5 w-5 '} onClick={() => setShowOptions(!showOptions)}>
          <SettingsSvg></SettingsSvg>
        </button>

        {showOptions && (
          <GridTitleOptionsPopup
            onClose={() => setShowOptions(!showOptions)}
            onFilterClick={() => onShowFilterClick()}
            onSortClick={() => onShowSortClick()}
          />
        )}
      </div>
    </div>
  );
};
