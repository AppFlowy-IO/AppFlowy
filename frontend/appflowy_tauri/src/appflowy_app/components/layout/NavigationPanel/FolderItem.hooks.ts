import { foldersActions, IFolder } from '../../../stores/reducers/folders/slice';
import { useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { nanoid } from 'nanoid';
import { IPage, pagesActions } from '../../../stores/reducers/pages/slice';
import {
  AppIdPB,
  CreateAppPayloadPB,
  CreateViewPayloadPB,
  UpdateAppPayloadPB,
  ViewDataFormatPB,
  ViewLayoutTypePB,
} from '../../../../services/backend';
import {
  FolderEventCreateApp,
  FolderEventCreateView,
  FolderEventDeleteApp,
  FolderEventUpdateApp,
} from '../../../../services/backend/events/flowy-folder';

const initialFolderHeight = 40;
const initialPageHeight = 40;
const animationDuration = 500;

export const useFolderEvents = (folder: IFolder, pages: IPage[]) => {
  const appDispatch = useAppDispatch();

  const [showPages, setShowPages] = useState(false);
  const [showFolderOptions, setShowFolderOptions] = useState(false);
  const [showNewPageOptions, setShowNewPageOptions] = useState(false);
  const [showRenamePopup, setShowRenamePopup] = useState(false);

  const [folderHeight, setFolderHeight] = useState(`${initialFolderHeight}px`);

  const workspace = useAppSelector((state) => state.workspace);

  const onFolderNameClick = () => {
    if (showPages) {
      setFolderHeight(`${initialFolderHeight}px`);
    } else {
      setFolderHeight(`${initialFolderHeight + pages.length * initialPageHeight}px`);
    }
    setShowPages(!showPages);
  };

  const onFolderOptionsClick = () => {
    setShowFolderOptions(!showFolderOptions);
  };

  const onNewPageClick = () => {
    setShowNewPageOptions(!showNewPageOptions);
  };

  const startFolderRename = () => {
    closePopup();
    setShowRenamePopup(true);
  };

  const changeFolderTitle = async (newTitle: string) => {
    await FolderEventUpdateApp(
      UpdateAppPayloadPB.fromObject({
        name: newTitle,
        desc: '',
        app_id: folder.id,
      })
    );
    appDispatch(foldersActions.renameFolder({ id: folder.id, newTitle }));
  };

  const closeRenamePopup = () => {
    setShowRenamePopup(false);
  };

  const deleteFolder = async () => {
    closePopup();
    await FolderEventDeleteApp(
      AppIdPB.fromObject({
        value: folder.id,
      })
    );
    appDispatch(foldersActions.deleteFolder({ id: folder.id }));
  };

  const duplicateFolder = async () => {
    closePopup();
    const createAppResult = await FolderEventCreateApp(
      CreateAppPayloadPB.fromObject({
        workspace_id: workspace.id,
        name: folder.title,
        desc: '',
      })
    );
    if (createAppResult.ok) {
      const pb = createAppResult.val;
      appDispatch(foldersActions.addFolder({ id: pb.id, title: folder.title }));
    } else {
      throw new Error('create folder error');
    }
  };

  const closePopup = () => {
    setShowFolderOptions(false);
    setShowNewPageOptions(false);
  };

  const onAddNewDocumentPage = async () => {
    closePopup();
    const createViewResult = await FolderEventCreateView(
      CreateViewPayloadPB.fromObject({
        name: 'New Page 1',
        layout: ViewLayoutTypePB.Document,
        belong_to_id: folder.id,
        data_format: ViewDataFormatPB.NodeFormat,
        desc: '',
        thumbnail: '',
        initial_data: new Uint8Array([]),
      })
    );
    if (createViewResult.ok) {
      const pb = createViewResult.val;
      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Document,
          title: pb.name,
          id: pb.id,
        })
      );
    } else {
      throw new Error('create view error');
    }
  };

  const onAddNewBoardPage = async () => {
    closePopup();
    const createViewResult = await FolderEventCreateView(
      CreateViewPayloadPB.fromObject({
        name: 'New Board 1',
        layout: ViewLayoutTypePB.Board,
        belong_to_id: folder.id,
        data_format: ViewDataFormatPB.DatabaseFormat,
        desc: '',
        thumbnail: '',
        initial_data: new Uint8Array([]),
      })
    );
    if (createViewResult.ok) {
      const pb = createViewResult.val;
      appDispatch(
        pagesActions.addPage({
          folderId: folder.id,
          pageType: ViewLayoutTypePB.Board,
          title: pb.name,
          id: pb.id,
        })
      );
    } else {
      throw new Error('create view error');
    }
  };

  const onAddNewGridPage = async () => {
    closePopup();
    const createViewResult = await FolderEventCreateView(
      CreateViewPayloadPB.fromObject({
        name: 'New Grid 1',
        layout: ViewLayoutTypePB.Grid,
        belong_to_id: folder.id,
        data_format: ViewDataFormatPB.DatabaseFormat,
        desc: '',
        thumbnail: '',
        initial_data: new Uint8Array([]),
      })
    );
    if (createViewResult.ok) {
      const pb = createViewResult.val;
      appDispatch(
        pagesActions.addPage({ folderId: folder.id, pageType: ViewLayoutTypePB.Grid, title: pb.name, id: pb.id })
      );
    } else {
      throw new Error('create view error');
    }
  };

  return {
    showPages,
    onFolderNameClick,
    showFolderOptions,
    onFolderOptionsClick,
    showNewPageOptions,
    onNewPageClick,

    showRenamePopup,
    startFolderRename,
    changeFolderTitle,
    closeRenamePopup,
    deleteFolder,
    duplicateFolder,

    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,

    closePopup,
    folderHeight,
    animationDuration,
  };
};
