import React, { useCallback } from 'react';
import { useNode } from './Node.hooks';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import TextBlock from '../TextBlock';
import { NodeContext } from '../_shared/SubscribeNode.hooks';
import { BlockType } from '$app/interfaces/document';
import HeadingBlock from '$app/components/document/HeadingBlock';
import TodoListBlock from '$app/components/document/TodoListBlock';
import QuoteBlock from '$app/components/document/QuoteBlock';

function NodeComponent({ id, ...props }: { id: string } & React.HTMLAttributes<HTMLDivElement>) {
  const { node, childIds, isSelected, ref } = useNode(id);

  const renderBlock = useCallback(() => {
    switch (node.type) {
      case BlockType.TextBlock: {
        return <TextBlock node={node} childIds={childIds} />;
      }
      case BlockType.HeadingBlock: {
        return <HeadingBlock node={node} />;
      }
      case BlockType.TodoListBlock: {
        return <TodoListBlock node={node} childIds={childIds} />;
      }
      case BlockType.QuoteBlock: {
        return <QuoteBlock node={node} childIds={childIds} />;
      }
      default:
        return null;
    }
  }, [node, childIds]);

  if (!node) return null;

  return (
    <NodeContext.Provider value={node}>
      <div {...props} ref={ref} data-block-id={node.id} className={`relative px-1  ${props.className}`}>
        {renderBlock()}
        <div className='block-overlay' />
        {isSelected ? (
          <div className='pointer-events-none absolute inset-0 z-[-1] m-[1px] rounded-[4px] bg-[#E0F8FF]' />
        ) : null}
      </div>
    </NodeContext.Provider>
  );
}

const NodeWithErrorBoundary = withErrorBoundary(NodeComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

export default React.memo(NodeWithErrorBoundary);
