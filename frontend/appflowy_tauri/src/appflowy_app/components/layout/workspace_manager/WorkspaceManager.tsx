import React from 'react';
import NewPageButton from '$app/components/layout/workspace_manager/NewPageButton';
import { useLoadWorkspaces } from '$app/components/layout/workspace_manager/Workspace.hooks';
import Workspace from './Workspace';
import TrashButton from '$app/components/layout/workspace_manager/TrashButton';

function WorkspaceManager() {
  const { workspaces, currentWorkspace } = useLoadWorkspaces();

  return (
    <div className={'workspaces flex h-full select-none flex-col justify-between'}>
      <div className={'mt-4 flex  w-full flex-1 select-none flex-col overflow-y-auto overflow-x-hidden'}>
        <div className={'flex-1'}>
          {workspaces.map((workspace) => (
            <Workspace opened={currentWorkspace?.id === workspace.id} key={workspace.id} workspace={workspace} />
          ))}
        </div>
      </div>
      <div className={'flex w-[100%] items-center px-2'}>
        <TrashButton />
      </div>
      {currentWorkspace && <NewPageButton workspaceId={currentWorkspace.id} />}
    </div>
  );
}

export default WorkspaceManager;
