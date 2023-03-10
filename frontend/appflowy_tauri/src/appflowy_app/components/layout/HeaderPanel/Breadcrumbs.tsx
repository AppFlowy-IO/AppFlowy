import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';
import { useEffect, useState } from 'react';
import { useAppSelector } from '../../../stores/store';
import { useLocation } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { activePageIdActions } from '../../../stores/reducers/activePageId/slice';

export const Breadcrumbs = ({ menuHidden, onShowMenuClick }: { menuHidden: boolean; onShowMenuClick: () => void }) => {
  const dispatch = useDispatch();
  const [folderName, setFolderName] = useState('');
  const [pageName, setPageName] = useState('');
  const activePageId = useAppSelector((state) => state.activePageId);
  const pagesStore = useAppSelector((state) => state.pages);
  const foldersStore = useAppSelector((state) => state.folders);
  const [pageHistory, setPageHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState(0);

  useEffect(() => {
    const page = pagesStore.find((p) => p.id === activePageId);
    const folder = foldersStore.find((f) => f.id === page?.folderId);
    setFolderName(folder?.title || '');
    setPageName(page?.title || '');
    setPageHistory([...pageHistory, activePageId]);
  }, [pagesStore, foldersStore, activePageId]);

  const currentLocation = useLocation();

  useEffect(() => {
    // if there is no active page, we should try to get the page id from the url
    if (!activePageId?.length) {
      const { pathname } = currentLocation;
      const parts = pathname.split('/');
      // `/"page"/{pageType}/{pageId}`
      if (parts.length !== 4) return;

      const pageId = parts[parts.length - 1];
      // const pageType = parts[parts.length - 2];

      dispatch(activePageIdActions.setActivePageId(pageId));
    }
  }, [activePageId, currentLocation]);

  return (
    <div className={'flex items-center'}>
      <div className={'mr-4 flex items-center'}>
        {menuHidden && (
          <button onClick={() => onShowMenuClick()} className={'mr-2 h-5 w-5'}>
            <ShowMenuSvg></ShowMenuSvg>
          </button>
        )}

        <button className={'p-1'} onClick={() => history.back()}>
          <img src={'/images/home/arrow_left.svg'} />
        </button>
        <button className={'p-1'} onClick={() => history.forward()}>
          <img src={'/images/home/arrow_right.svg'} />
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
