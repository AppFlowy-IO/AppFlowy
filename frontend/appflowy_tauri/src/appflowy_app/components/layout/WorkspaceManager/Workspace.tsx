import React from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import NestedViews from '$app/components/layout/WorkspaceManager/NestedPages';

function Workspace({ workspace, opened }: { workspace: WorkspaceItem; opened: boolean }) {
  return (
    <div className={'flex h-[100%] flex-col'}>
      <div
        style={{
          height: opened ? '100%' : 0,
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
