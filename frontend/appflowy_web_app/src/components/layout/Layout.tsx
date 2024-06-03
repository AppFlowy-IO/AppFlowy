import { YFolder, YjsEditorKey } from '@/application/collab.type';
import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import Header from '@/components/layout/Header';
import { AFScroller } from '@/components/_shared/scroller';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import './layout.scss';

function Layout({ children }: { children: React.ReactNode }) {
  const { workspaceId } = useParams();
  const folderService = useContext(AFConfigContext)?.service?.folderService;
  const [folder, setFolder] = useState<YFolder | null>(null);
  const getFolder = useCallback(
    async (workspaceId: string) => {
      const folder = (await folderService?.openWorkspace(workspaceId))
        ?.getMap(YjsEditorKey.data_section)
        .get(YjsEditorKey.folder);

      if (!folder) return;

      console.log(folder.toJSON());
      setFolder(folder);
    },
    [folderService]
  );

  useEffect(() => {
    if (!workspaceId) return;

    void getFolder(workspaceId);
  }, [getFolder, workspaceId]);
  return (
    <FolderProvider folder={folder}>
      <Header />
      <AFScroller
        overflowXHidden
        style={{
          height: 'calc(100vh - 64px)',
        }}
        className={'appflowy-layout appflowy-scroll-container'}
      >
        {children}
      </AFScroller>
    </FolderProvider>
  );
}

export default Layout;
