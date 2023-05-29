import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';
import { useEffect, useState } from 'react';
import { useAppSelector } from '../../../stores/store';
import { useLocation } from 'react-router-dom';

export const Breadcrumbs = ({ menuHidden, onShowMenuClick }: { menuHidden: boolean; onShowMenuClick: () => void }) => {
  const [folderName, setFolderName] = useState('');
  const [pageName, setPageName] = useState('');
  const [activePageId, setActivePageId] = useState<string>('');
  const currentLocation = useLocation();
  const pagesStore = useAppSelector((state) => state.pages);
  const foldersStore = useAppSelector((state) => state.folders);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];
    setActivePageId(pageId);
  }, [currentLocation]);

  useEffect(() => {
    const page = pagesStore.find((p) => p.id === activePageId);
    const folder = foldersStore.find((f) => f.id === page?.folderId);
    setFolderName(folder?.title ?? '');
    setPageName(page?.title ?? '');
  }, [pagesStore, foldersStore, activePageId]);

  return (
    <div className={'flex items-center'}>
      <div className={'mr-4 flex items-center'}>
        {menuHidden && (
          <button onClick={() => onShowMenuClick()} className={'mr-2 h-5 w-5'}>
            <ShowMenuSvg></ShowMenuSvg>
          </button>
        )}

        <button className={'p-1'} onClick={() => history.back()}>
          <img src={'/images/home/arrow_left.svg'} alt={''} />
        </button>
        <button className={'p-1'} onClick={() => history.forward()}>
          <img src={'/images/home/arrow_right.svg'} alt={''} />
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
