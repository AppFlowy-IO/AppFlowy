import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { useState } from 'react';
import { nanoid } from 'nanoid';
import { ViewBackendService } from '../../../stores/effects/folder/view/view_bd_svc';
import { useError } from '../../error/Error.hooks';

export const usePageEvents = (page: IPage) => {
  const appDispatch = useAppDispatch();
  const [showPageOptions, setShowPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);
  const activePageId = useAppSelector((state) => state.activePageId);
  const viewBackendService: ViewBackendService = new ViewBackendService(page.id);
  const error = useError();

  const onPageOptionsClick = () => {
    setShowPageOptions(!showPageOptions);
  };

  const startPageRename = () => {
    setShowRenamePopup(true);
    closePopup();
  };

  const changePageTitle = async (newTitle: string) => {
    try {
      await viewBackendService.update({ name: newTitle });
      appDispatch(pagesActions.renamePage({ id: page.id, newTitle }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const deletePage = async () => {
    closePopup();
    try {
      await viewBackendService.delete();
      appDispatch(pagesActions.deletePage({ id: page.id }));
    } catch (e: any) {
      error.showError(e?.message);
    }
  };

  const duplicatePage = () => {
    closePopup();
    try {
      appDispatch(
        pagesActions.addPage({ id: nanoid(8), pageType: page.pageType, title: page.title, folderId: page.folderId })
      );
    } catch (e: any) {
      error.showError(e?.message);
    }
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
