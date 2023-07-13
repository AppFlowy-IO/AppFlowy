import React from 'react';
import NewPageButton from '$app/components/layout/WorkspaceManager/NewPageButton';
import { useLoadWorkspaces } from '$app/components/layout/WorkspaceManager/Workspace.hooks';
import Workspace from './Workspace';
import { List } from '@mui/material';
import TrashButton from '$app/components/layout/WorkspaceManager/TrashButton';

function WorkspaceManager() {
  const { workspaces, currentWorkspace } = useLoadWorkspaces();

  return (
    <div className={'flex h-[100%] flex-col justify-between'}>
      <List className={'flex-1 overflow-y-auto overflow-x-hidden'}>
        {workspaces.map((workspace) => (
          <Workspace opened={currentWorkspace?.id === workspace.id} key={workspace.id} workspace={workspace} />
        ))}
      </List>
      <div className={'flex h-[48px] w-[100%] items-center px-2'}>
        <TrashButton />
      </div>
      {currentWorkspace && <NewPageButton workspaceId={currentWorkspace.id} />}
    </div>
  );
}

export default WorkspaceManager;
