import { useNavigationPanelHooks } from './NavigationPanel.hooks';
import AddSvg from '../_shared/AddSvg';

export const NavigationPanel = () => {
  const {
    currentUser,
    width,
    folders,
    onAddFolder,
    onFolderChange,
    isFolderOpen,
    setFolderOpen,
    pages,
    onAddNewPage,
    onPageChange,
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
            <div key={index}>
              <div className={'px-4 py-2 my-2 flex items-center justify-between rounded-lg hover:bg-surface-2'}>
                <div
                  onClick={() => setFolderOpen(folder.id, !isFolderOpen[folder.id])}
                  className={'flex items-center flex-1 min-w-0 cursor-pointer '}
                >
                  <div
                    className={`mr-2 transition-transform duration-500 ${isFolderOpen[folder.id] ? 'rotate-180' : ''}`}
                  >
                    <img className={''} src={'/images/home/drop_down_show.svg'} alt={''} />
                  </div>
                  <span className={'whitespace-normal min-w-0 flex-1'}>{folder.title}</span>
                  {/* <input
                    className={'whitespace-normal min-w-0 flex-1'}
                    value={folder.title}
                    onChange={(e) => onFolderChange(folder.id, e.target.value)}
                  />*/}
                </div>
                <button onClick={() => onAddNewPage(folder.id)} className={'text-black hover:text-main-accent'}>
                  <AddSvg></AddSvg>
                </button>
              </div>
              {isFolderOpen[folder.id] &&
                pages
                  .filter((page) => page.folderId === folder.id)
                  .map((page, index2) => (
                    <div
                      key={index2}
                      className={
                        'px-4 py-2 cursor-pointer flex items-center justify-between rounded-lg hover:bg-surface-2'
                      }
                    >
                      <div
                        onClick={() => console.log('open page: ', page.id)}
                        className={'flex items-center flex-1 min-w-0 pl-[24px]'}
                      >
                        <span className={'whitespace-normal min-w-0 flex-1 ml-2'}>{page.title}</span>
                        {/*<input
                      className={'whitespace-normal min-w-0 flex-1 ml-2'}
                      value={page.title}
                      onChange={(e) => onPageChange(page.id, e.target.value)}
                    />*/}
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
            <span className={'text-white'}>
              <AddSvg></AddSvg>
            </span>
          </div>
          <span>New Folder</span>
        </button>
      </div>
    </div>
  );
};
