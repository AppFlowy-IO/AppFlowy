import React, { useEffect } from 'react';
import NewPageButton from '$app/components/layout/workspace_manager/NewPageButton';
import { useLoadWorkspaces } from '$app/components/layout/workspace_manager/Workspace.hooks';
import Workspace from './Workspace';
import TrashButton from '$app/components/layout/workspace_manager/TrashButton';
import { useAppSelector } from '@/appflowy_app/stores/store';
import { LoginState } from '$app_reducers/current-user/slice';
import { AFScroller } from '$app/components/_shared/scroller';

function WorkspaceManager() {
  const { workspaces, currentWorkspace, initializeWorkspaces } = useLoadWorkspaces();

  const loginState = useAppSelector((state) => state.currentUser.loginState);

  useEffect(() => {
    if (loginState === LoginState.Success || loginState === undefined) {
      void initializeWorkspaces();
    }
  }, [initializeWorkspaces, loginState]);

  return (
    <div className={'workspaces flex h-full select-none flex-col justify-between'}>
      <AFScroller overflowXHidden className={'mt-4 flex  w-full flex-1 select-none flex-col'}>
        <div className={'flex-1'}>
          {workspaces.map((workspace) => (
            <Workspace opened={currentWorkspace?.id === workspace.id} key={workspace.id} workspace={workspace} />
          ))}
        </div>
      </AFScroller>
      <div className={'flex w-[100%] items-center px-2'}>
        <TrashButton />
      </div>
      {currentWorkspace && <NewPageButton workspaceId={currentWorkspace.id} />}
    </div>
  );
}

export default WorkspaceManager;
