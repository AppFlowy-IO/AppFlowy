import React from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import NestedViews from '$app/components/layout/WorkspaceManager/NestedPages';
import { useLoadWorkspace } from '$app/components/layout/WorkspaceManager/Workspace.hooks';
import WorkspaceTitle from '$app/components/layout/WorkspaceManager/WorkspaceTitle';

function Workspace({ workspace, opened }: { workspace: WorkspaceItem; opened: boolean }) {
  const { openWorkspace, deleteWorkspace } = useLoadWorkspace(workspace);

  return (
    <div className={'flex flex-col'}>
      <div
        style={{
          height: opened ? 'auto' : 0,
          overflow: 'hidden',
          transition: 'height 0.2s ease-in-out',
        }}
      >
        {/*<WorkspaceTitle workspace={workspace} openWorkspace={openWorkspace} onDelete={onDelete} />*/}
        <NestedViews workspaceId={workspace.id} />
      </div>
    </div>
  );
}

export default Workspace;
