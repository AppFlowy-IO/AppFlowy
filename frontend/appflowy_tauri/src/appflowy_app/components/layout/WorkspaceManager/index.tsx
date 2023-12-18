import React from 'react';
import NewPageButton from '$app/components/layout/WorkspaceManager/NewPageButton';
import { useLoadWorkspaces } from '$app/components/layout/WorkspaceManager/Workspace.hooks';
import Workspace from './Workspace';
import TrashButton from '$app/components/layout/WorkspaceManager/TrashButton';

function WorkspaceManager() {
  const { workspaces, currentWorkspace } = useLoadWorkspaces();

  return (
    <div className={'flex h-full flex-col justify-between'}>
      <div className={'flex w-full flex-1 flex-col'}>
        <div className={'flex-1 overflow-hidden'}>
          {workspaces.map((workspace) => (
            <Workspace opened={currentWorkspace?.id === workspace.id} key={workspace.id} workspace={workspace} />
          ))}
        </div>
        <div className={'sticky bottom-0 flex h-[48px] w-[100%] items-center px-2'}>
          <TrashButton />
        </div>
      </div>

      {currentWorkspace && <NewPageButton workspaceId={currentWorkspace.id} />}
    </div>
  );
}

export default WorkspaceManager;
