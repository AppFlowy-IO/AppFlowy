import React, { useCallback } from 'react';
import { useNode } from './Node.hooks';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import TextBlock from '../TextBlock';

function NodeComponent({ id }: { id: string }) {
  const { node, childIds } = useNode(id);

  const renderBlock = useCallback((props: { node: Node; childIds?: string[] }) => {
    switch (props.node.type) {
      case 'text':
        return <TextBlock {...props} />;
      default:
        break;
    }
  }, []);

  if (!node) return null;

  return (
    <div data-block-id={node.id} className='relative my-[1px]'>
      {renderBlock({
        node,
        childIds,
      })}
      <div className='block-overlay' />
    </div>
  );
}

const NodeWithErrorBoundary = withErrorBoundary(NodeComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

export default React.memo(NodeWithErrorBoundary);
