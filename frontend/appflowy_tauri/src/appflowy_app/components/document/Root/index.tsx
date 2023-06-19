import { DocumentData } from '@/appflowy_app/interfaces/document';
import React, { useCallback } from 'react';
import { useRoot } from './Root.hooks';
import Node from '../Node';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import VirtualizedList from '../VirtualizedList';
import { Skeleton } from '@mui/material';

function Root({ documentData }: { documentData: DocumentData }) {
  const { node, childIds } = useRoot({ documentData });

  const renderNode = useCallback((nodeId: string) => {
    return <Node key={nodeId} id={nodeId} />;
  }, []);

  if (!node || !childIds) {
    return <Skeleton />;
  }

  return (
    <>
      <div id='appflowy-block-doc' className='h-[100%] overflow-hidden caret-custom-caret'>
        <VirtualizedList node={node} childIds={childIds} renderNode={renderNode} />
      </div>
    </>
  );
}

const RootWithErrorBoundary = withErrorBoundary(Root, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

export default React.memo(RootWithErrorBoundary);
