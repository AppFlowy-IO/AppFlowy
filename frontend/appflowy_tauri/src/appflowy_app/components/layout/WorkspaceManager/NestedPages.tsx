import React from 'react';
import { useAppSelector } from '$app/stores/store';
import NestedPage from '$app/components/layout/NestedPage';

function WorkspaceNestedPages({ workspaceId }: { workspaceId: string }) {
  const pageIds = useAppSelector((state) => {
    return state.pages.relationMap[workspaceId];
  });

  return (
    <div className={'h-full'}>
      {pageIds?.map((pageId) => (
        <NestedPage key={pageId} pageId={pageId} />
      ))}
    </div>
  );
}

export default WorkspaceNestedPages;
