import { SettingsSvg } from '../../_shared/svg/SettingsSvg';
import { GridTitleOptionsPopup } from './GridTitleOptionsPopup';
import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { useAppSelector } from '$app/stores/store';

export const GridTitle = ({
  onShowFilterClick,
  onShowSortClick,
}: {
  onShowFilterClick: () => void;
  onShowSortClick: () => void;
}) => {
  const [showOptions, setShowOptions] = useState(false);
  const currentLocation = useLocation();
  const pagesStore = useAppSelector((state) => state.pages);
  const [activePageId, setActivePageId] = useState<string>('');
  const [pageName, setPageName] = useState('');

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];

    setActivePageId(pageId);
  }, [currentLocation]);

  useEffect(() => {
    const page = pagesStore.find((p) => p.id === activePageId);

    setPageName(page?.title ?? '');
  }, [pagesStore, activePageId]);

  return (
    <div className={'relative flex items-center '}>
      <div className='flex '>
        <div>{pageName}</div>
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
