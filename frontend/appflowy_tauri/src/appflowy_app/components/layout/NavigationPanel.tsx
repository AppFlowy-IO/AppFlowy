import { useNavigationPanelHooks } from './NavigationPanel.hooks';
import AddSvg from '../_shared/AddSvg';
import { Details2Svg } from '../_shared/Details2Svg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { NewPagePopup } from './NewPagePopup';
import { DocumentSvg } from '../_shared/DocumentSvg';
import { BoardSvg } from '../_shared/BoardSvg';
import { GridSvg } from '../_shared/GridSvg';

export const NavigationPanel = () => {
  const {
    currentUser,
    width,

    folders,
    isFolderOpen,
    setFolderOpen,
    onFolderDetailsClick,
    onAddFolder,
    startFolderRename,
    renamingFolderId,
    onFolderChange,
    completeFolderRename,
    deleteFolder,
    duplicateFolder,

    onAddNewPageClick,

    pages,
    onPageDetailsClick,
    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,
    startPageRename,
    renamingPageId,
    onPageChange,
    completePageRename,
    deletePage,
    duplicatePage,

    detailsPopupOpenId,
    addPagePopupOpenId,
    closePopup,

    navigate,
  } = useNavigationPanelHooks();

  return (
    <div
      className={'bg-surface-1 border-r border-shade-6 flex flex-col justify-between text-sm'}
      style={{ width: `${width}px` }}
    >
      <div className={'flex flex-col'}>
        <div className={'px-6 h-[60px] mb-2 flex items-center justify-between'}>
          <img src={'/images/flowy_logo_with_text.svg'} alt={'logo'} />
          <img src={'/images/home/hide_menu.svg'} alt={'hide'} />
        </div>

        <div className={'px-2 py-2 flex items-center justify-between'}>
          <button className={'pl-4 flex items-center'}>
            <img className={'mr-2'} src={'/images/home/person.svg'} />
            <span>{currentUser.displayName}</span>
          </button>
          <button className={'p-2 mr-2 rounded-lg hover:bg-surface-2'}>
            <img src={'/images/home/settings.svg'} alt={'settings'} />
          </button>
        </div>

        <div className={'px-2 flex flex-col'}>
          {folders.map((folder, index) => (
            <div key={index} className={'my-2'}>
              <div className={'px-4 py-2 flex items-center justify-between rounded-lg hover:bg-surface-2'}>
                <div
                  onClick={() => renamingFolderId !== folder.id && setFolderOpen(folder.id, !isFolderOpen[folder.id])}
                  className={'flex items-center flex-1 min-w-0 cursor-pointer '}
                >
                  <div
                    className={`mr-2 transition-transform duration-500 ${isFolderOpen[folder.id] ? 'rotate-180' : ''}`}
                  >
                    <img className={''} src={'/images/home/drop_down_show.svg'} alt={''} />
                  </div>
                  {renamingFolderId === folder.id ? (
                    <input
                      className={'whitespace-normal min-w-0 flex-1 bg-main-warning text-white'}
                      value={folder.title}
                      onKeyPress={(e) => e.code === 'Enter' && completeFolderRename()}
                      onChange={(e) => onFolderChange(folder.id, e.target.value)}
                    />
                  ) : (
                    <span className={'whitespace-nowrap overflow-ellipsis overflow-hidden min-w-0 flex-1'}>
                      {folder.title}
                    </span>
                  )}
                </div>
                <div className={'flex items-center relative'}>
                  <button
                    onClick={() => onFolderDetailsClick(folder)}
                    className={'text-black hover:text-main-accent w-[24px] h-[24px]'}
                  >
                    <Details2Svg></Details2Svg>
                  </button>
                  <button
                    onClick={() => onAddNewPageClick(folder.id)}
                    className={'text-black hover:text-main-accent w-[24px] h-[24px]'}
                  >
                    <AddSvg></AddSvg>
                  </button>
                  {detailsPopupOpenId === folder.id && (
                    <NavItemOptionsPopup
                      onRenameClick={() => startFolderRename(folder)}
                      onDeleteClick={() => deleteFolder(folder)}
                      onDuplicateClick={() => duplicateFolder(folder)}
                      onClose={() => closePopup()}
                    ></NavItemOptionsPopup>
                  )}
                  {addPagePopupOpenId === folder.id && (
                    <NewPagePopup
                      onDocumentClick={() => onAddNewDocumentPage(folder.id)}
                      onBoardClick={() => onAddNewBoardPage(folder.id)}
                      onGridClick={() => onAddNewGridPage(folder.id)}
                      onClose={() => closePopup()}
                    ></NewPagePopup>
                  )}
                </div>
              </div>
              {isFolderOpen[folder.id] &&
                pages
                  .filter((page) => page.folderId === folder.id)
                  .map((page, index2) => (
                    <div
                      key={index2}
                      className={
                        'pl-8 pr-4 py-2 cursor-pointer flex items-center justify-between rounded-lg hover:bg-surface-2'
                      }
                    >
                      <div
                        onClick={() => renamingPageId !== page.id && navigate(`/page/${page.id}`)}
                        className={'flex items-center flex-1 min-w-0'}
                      >
                        <div className={'ml-1 w-[16px] h-[16px] mr-1'}>
                          {page.pageType === 'document' && <DocumentSvg></DocumentSvg>}
                          {page.pageType === 'board' && <BoardSvg></BoardSvg>}
                          {page.pageType === 'grid' && <GridSvg></GridSvg>}
                        </div>
                        {renamingPageId === page.id ? (
                          <input
                            className={'whitespace-normal min-w-0 flex-1 bg-main-warning text-white'}
                            value={page.title}
                            onKeyPress={(e) => e.code === 'Enter' && completePageRename()}
                            onChange={(e) => onPageChange(page.id, e.target.value)}
                          />
                        ) : (
                          <span className={'whitespace-nowrap overflow-ellipsis overflow-hidden min-w-0 flex-1 ml-2'}>
                            {page.title}
                          </span>
                        )}
                      </div>
                      <div className={'flex items-center relative'}>
                        <button
                          onClick={() => onPageDetailsClick(page)}
                          className={'text-black hover:text-main-accent w-[24px] h-[24px]'}
                        >
                          <Details2Svg></Details2Svg>
                        </button>
                        {detailsPopupOpenId === page.id && (
                          <NavItemOptionsPopup
                            onRenameClick={() => startPageRename(page)}
                            onDeleteClick={() => deletePage(page)}
                            onDuplicateClick={() => duplicatePage(page)}
                            onClose={() => closePopup()}
                          ></NavItemOptionsPopup>
                        )}
                      </div>
                    </div>
                  ))}
            </div>
          ))}
        </div>
      </div>

      <div className={'flex flex-col'}>
        <div className={'border-b border-shade-6 pb-4 px-2'}>
          <button className={'flex items-center px-4 py-2 rounded-lg w-full hover:bg-surface-2'}>
            <img className={'mr-2 w-[24px] h-[24px]'} src={'/images/home/page.svg'} alt={''} />
            <span>Plugins</span>
          </button>
          <button className={'flex items-center px-4 py-2 rounded-lg w-full hover:bg-surface-2'}>
            <img className={'mr-2'} src={'/images/home/trash.svg'} alt={''} />
            <span>Trash</span>
          </button>
        </div>

        <button onClick={onAddFolder} className={'flex items-center w-full hover:bg-surface-2 px-6 h-[50px]'}>
          <div className={'bg-main-accent rounded-full text-white mr-2'}>
            <div className={'text-white w-[24px] h-[24px]'}>
              <AddSvg></AddSvg>
            </div>
          </div>
          <span>New Folder</span>
        </button>
      </div>
    </div>
  );
};
