import { DocumentData } from '@/appflowy_app/interfaces/document';
import React, { useCallback } from 'react';
import { useRoot } from './Root.hooks';
import Node from '../Node';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import VirtualizedList from '../VirtualizedList';
import { Skeleton } from '@mui/material';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

function Root({
  documentData,
  getDocumentTitle,
}: {
  documentData: DocumentData;
  getDocumentTitle?: () => React.ReactNode;
}) {
  const { node, childIds } = useRoot({ documentData });
  const { docId } = useSubscribeDocument();
  const renderNode = useCallback((nodeId: string) => {
    return <Node key={nodeId} id={nodeId} />;
  }, []);

  if (!node || !childIds) {
    return <Skeleton />;
  }

  return (
    <>
      <div
        id={`appflowy-block-doc-${docId}`}
        className='h-[100%] overflow-hidden text-base text-text-title caret-text-title'
      >
        <VirtualizedList getDocumentTitle={getDocumentTitle} node={node} childIds={childIds} renderNode={renderNode} />
      </div>
    </>
  );
}

const RootWithErrorBoundary = withErrorBoundary(React.memo(Root), {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

export default RootWithErrorBoundary;
