import { IPage, pagesActions } from '$app_reducers/pages/slice';
import { useAppDispatch } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { ViewBackendService } from '$app/stores/effects/folder/view/view_bd_svc';
import { useLocation } from 'react-router-dom';
import { ViewPB } from '@/services/backend';

export const usePageEvents = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const [showPageOptions, setShowPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);
  const [activePageId, setActivePageId] = useState<string>('');
  const currentLocation = useLocation();
  const viewBackendService: ViewBackendService = new ViewBackendService(page.id);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];
    setActivePageId(pageId);
  }, [currentLocation]);

  const onPageOptionsClick = () => {
    setShowPageOptions(!showPageOptions);
  };

  const startPageRename = () => {
    setShowRenamePopup(true);
    closePopup();
  };

  const changePageTitle = async (newTitle: string) => {
    await viewBackendService.update({ name: newTitle });
    appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
  };

  const deletePage = async () => {
    closePopup();
    await viewBackendService.delete();
    appDispatch(pagesActions.deletePage({ id: page.id }));
  };

  const duplicatePage = async () => {
    closePopup();
    await viewBackendService.duplicate(ViewPB.fromObject(page));
  };

  const closePopup = () => {
    setShowPageOptions(false);
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  return {
    showPageOptions,
    onPageOptionsClick,
    showRenamePopup,
    startPageRename,
    changePageTitle,
    deletePage,
    duplicatePage,
    closePopup,
    closeRenamePopup,
    activePageId,
  };
};
