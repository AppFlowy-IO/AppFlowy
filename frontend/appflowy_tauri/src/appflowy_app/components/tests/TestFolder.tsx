import React from 'react';
import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { useAppSelector } from '$app/stores/store';
import { WorkspaceBackendService } from '$app/stores/effects/folder/workspace/workspace_bd_svc';
import { ViewLayoutPB, ViewPB } from '@/services/backend';

const testCreateFolder = async (userId?: number) => {
  if (!userId) {
    console.log('user is not logged in');
    return;
  }
  console.log('test create views');
  const userBackendService: UserBackendService = new UserBackendService(userId);
  const workspaces = await userBackendService.getWorkspaces();
  if (workspaces.ok) {
    console.log('workspaces: ', workspaces.val.toObject());
  }
  const currentWorkspace = await userBackendService.getCurrentWorkspace();

  const workspaceService = new WorkspaceBackendService(currentWorkspace.workspace.id);
  const rootViews: ViewPB[] = [];
  for (let i = 1; i <= 3; i++) {
    const result = await workspaceService.createView({
      name: `test board ${i}`,
      desc: 'test description',
      layoutType: ViewLayoutPB.Board,
    });
    if (result.ok) {
      rootViews.push(result.val);
    }
  }
  for (let i = 1; i <= 3; i++) {
    const result = await workspaceService.createView({
      name: `test board 1 ${i}`,
      desc: 'test description',
      layoutType: ViewLayoutPB.Board,
      parentViewId: rootViews[0].id,
    });
  }

  const allApps = await workspaceService.getAllViews();
  console.log(allApps);
};

export const TestCreateViews = () => {
  const currentUser = useAppSelector((state) => state.currentUser);

  return TestButton('Test create views', testCreateFolder, currentUser.id);
};

const TestButton = (title: string, onClick: (userId?: number) => void, userId?: number) => {
  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-pink-200 p-4' type='button' onClick={() => onClick(userId)}>
          {title}
        </button>
      </div>
    </React.Fragment>
  );
};
