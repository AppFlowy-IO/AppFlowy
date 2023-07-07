import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';
import { useEffect, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { useLocation } from 'react-router-dom';
import { ArrowLeft, ArrowRight } from '@mui/icons-material';
import { ArrowLeftSvg } from '$app/components/_shared/svg/ArrowLeftSvg';
import { ArrowRightSvg } from '$app/components/_shared/svg/ArrowRightSvg';

export const Breadcrumbs = ({ menuHidden, onShowMenuClick }: { menuHidden: boolean; onShowMenuClick: () => void }) => {
  const [folderName, setFolderName] = useState('');
  const [pageName, setPageName] = useState('');
  const [activePageId, setActivePageId] = useState<string>('');
  const currentLocation = useLocation();
  const pagesStore = useAppSelector((state) => state.pages);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];

    setActivePageId(pageId);
  }, [currentLocation]);

  useEffect(() => {
    const page = pagesStore.find((p) => p.id === activePageId);

    // const folder = foldersStore.find((f) => f.id === page?.parentPageId);
    // setFolderName(folder?.title ?? '');
    setPageName(page?.title ?? '');
  }, [pagesStore, activePageId]);

  return (
    <div className={'flex items-center'}>
      <div className={'mr-4 flex items-center'}>
        {menuHidden && (
          <button onClick={() => onShowMenuClick()} className={'mr-2 h-5 w-5 text-text-title'}>
            <ShowMenuSvg></ShowMenuSvg>
          </button>
        )}

        <button className={'h-6 w-6 rounded p-1 text-text-title hover:bg-fill-hover'} onClick={() => history.back()}>
          <ArrowLeftSvg />
        </button>
        <button className={'h-6 w-6 rounded p-1 text-text-title hover:bg-fill-hover'} onClick={() => history.forward()}>
          <ArrowRightSvg />
        </button>
      </div>
      <div className={'mr-8 flex items-center gap-4'}>
        <span>{folderName}</span>
        <span>/</span>
        <span>{pageName}</span>
      </div>
    </div>
  );
};
