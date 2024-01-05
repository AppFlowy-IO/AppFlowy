import React from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import NestedViews from '$app/components/layout/WorkspaceManager/NestedPages';
import { useLoadWorkspace } from '$app/components/layout/WorkspaceManager/Workspace.hooks';

function Workspace({ workspace, opened }: { workspace: WorkspaceItem; opened: boolean }) {
  useLoadWorkspace(workspace);
  return (
    <>
      <div
        style={{
          height: opened ? '100%' : 0,
          overflow: 'hidden',
          transition: 'height 0.2s ease-in-out',
        }}
      >
        <NestedViews workspaceId={workspace.id} />
      </div>
    </>
  );
}

export default Workspace;
