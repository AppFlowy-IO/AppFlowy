import React from 'react';
import { useAppSelector } from '$app/stores/store';
import NestedPage from '$app/components/layout/NestedPage';
import { List } from '@mui/material';

function WorkspaceNestedPages({ workspaceId }: { workspaceId: string }) {
  const pageIds = useAppSelector((state) => {
    return state.pages.childPages[workspaceId];
  });

  return (
    <List className={'h-[100%] overflow-y-auto overflow-x-hidden'}>
      {pageIds?.map((pageId) => (
        <NestedPage key={pageId} pageId={pageId} />
      ))}
    </List>
  );
}

export default WorkspaceNestedPages;
