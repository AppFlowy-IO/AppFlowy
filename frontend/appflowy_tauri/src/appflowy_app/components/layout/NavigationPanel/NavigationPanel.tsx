import { useNavigationPanelHooks } from './NavigationPanel.hooks';
import { Workspace } from '../Workspace';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { PluginsButton } from './PluginsButton';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { NavigationResizer } from './NavigationResizer';

export const NavigationPanel = () => {
  const {
    width,

    folders,
    pages,

    navigate,
  } = useNavigationPanelHooks();

  return (
    <>
      <div className={'flex flex-col justify-between bg-surface-1 text-sm'} style={{ width: `${width}px` }}>
        <div className={'flex flex-col'}>
          <AppLogo></AppLogo>

          <Workspace></Workspace>

          <div className={'flex flex-col px-2'}>
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
          <div className={'border-b border-shade-6 px-2 pb-4'}>
            <PluginsButton></PluginsButton>
            <TrashButton></TrashButton>
          </div>

          <NewFolderButton></NewFolderButton>
        </div>
      </div>
      <NavigationResizer></NavigationResizer>
    </>
  );
};
