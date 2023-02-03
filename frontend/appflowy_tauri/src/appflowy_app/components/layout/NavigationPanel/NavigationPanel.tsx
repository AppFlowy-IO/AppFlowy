import { useNavigationPanelHooks } from './NavigationPanel.hooks';
import { Workspace } from '../Workspace';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { PluginsButton } from './PluginsButton';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';

export const NavigationPanel = () => {
  const {
    width,

    folders,
    pages,

    navigate,
  } = useNavigationPanelHooks();

  return (
    <div
      className={'bg-surface-1 border-r border-shade-6 flex flex-col justify-between text-sm'}
      style={{ width: `${width}px` }}
    >
      <div className={'flex flex-col'}>
        <AppLogo></AppLogo>

        <Workspace></Workspace>

        <div className={'px-2 flex flex-col'}>
          {folders.map((folder, index) => (
            <FolderItem
              key={index}
              folder={folder}
              pages={pages.filter((page) => page.folderId === folder.id)}
              onPageClick={(page) => navigate(`/page/${page.pageType}/${page.id}`)}
            ></FolderItem>
          ))}
        </div>
      </div>

      <div className={'flex flex-col'}>
        <div className={'border-b border-shade-6 pb-4 px-2'}>
          <PluginsButton></PluginsButton>
          <TrashButton></TrashButton>
        </div>

        <NewFolderButton></NewFolderButton>
      </div>
    </div>
  );
};
