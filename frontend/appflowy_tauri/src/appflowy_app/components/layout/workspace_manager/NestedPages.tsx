import React from 'react';
import { useAppSelector } from '$app/stores/store';
import NestedPage from '$app/components/layout/nested_page/NestedPage';

function WorkspaceNestedPages({ workspaceId }: { workspaceId: string }) {
  const pageIds = useAppSelector((state) => {
    return state.pages.relationMap[workspaceId];
  });

  return (
    <div className={'h-full w-full overflow-x-hidden p-4 text-xs'}>
      {pageIds?.map((pageId) => (
        <NestedPage key={pageId} pageId={pageId} />
      ))}
    </div>
  );
}

export default WorkspaceNestedPages;
