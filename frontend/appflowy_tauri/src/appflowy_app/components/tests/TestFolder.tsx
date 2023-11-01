import React from 'react';
import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { useAppSelector } from '$app/stores/store';
import { WorkspaceController } from '../../stores/effects/workspace/workspace_controller';
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

  const currentWorkspaceSetting = await userBackendService.getCurrentWorkspaceSetting();
  const workspaceService = new WorkspaceController(currentWorkspaceSetting.workspace_id);
  const rootViews: ViewPB[] = [];

  for (let i = 1; i <= 3; i++) {
    const result = await workspaceService.createView({
      name: `test board ${i}`,
      desc: 'test description',
      layout: ViewLayoutPB.Board,
    });

    rootViews.push(result);
  }

  for (let i = 1; i <= 3; i++) {
    const result = await workspaceService.createView({
      name: `test board 1 ${i}`,
      desc: 'test description',
      layout: ViewLayoutPB.Board,
      parent_view_id: rootViews[0].id,
    });
  }

  const allApps = await workspaceService.getChildPages();

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
