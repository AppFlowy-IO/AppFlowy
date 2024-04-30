import { useViewsIdSelector } from '@/application/folder-yjs';
import ViewItem from '@/components/folder/ViewItem';
import React from 'react';

export function Folder() {
  const { viewsId } = useViewsIdSelector();

  return (
    <div className={'m-10 p-10'}>
      {viewsId.map((viewId) => {
        return <ViewItem key={viewId} id={viewId} />;
      })}
    </div>
  );
}

export default Folder;
