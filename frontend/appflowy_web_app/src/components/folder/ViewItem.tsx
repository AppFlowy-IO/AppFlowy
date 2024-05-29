import { useNavigateToView } from '@/application/folder-yjs';
import React from 'react';
import Page from '@/components/_shared/page/Page';

function ViewItem({ id }: { id: string }) {
  const onNavigateToView = useNavigateToView();

  return (
    <div className={'cursor-pointer border-b border-line-border py-4 px-2'}>
      <Page
        onClick={() => {
          onNavigateToView?.(id);
        }}
        id={id}
      />
    </div>
  );
}

export default ViewItem;
