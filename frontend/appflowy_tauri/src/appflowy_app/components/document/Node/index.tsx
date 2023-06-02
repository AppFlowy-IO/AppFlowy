import React, { useCallback } from 'react';
import { useNode } from './Node.hooks';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import TextBlock from '../TextBlock';
import { BlockType } from '$app/interfaces/document';
import { Alert } from '@mui/material';

import HeadingBlock from '$app/components/document/HeadingBlock';
import TodoListBlock from '$app/components/document/TodoListBlock';
import QuoteBlock from '$app/components/document/QuoteBlock';
import BulletedListBlock from '$app/components/document/BulletedListBlock';
import NumberedListBlock from '$app/components/document/NumberedListBlock';
import ToggleListBlock from '$app/components/document/ToggleListBlock';
import DividerBlock from '$app/components/document/DividerBlock';
import CalloutBlock from '$app/components/document/CalloutBlock';
import BlockOverlay from '$app/components/document/Overlay/BlockOverlay';
import CodeBlock from '$app/components/document/CodeBlock';

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
      case BlockType.BulletedListBlock: {
        return <BulletedListBlock node={node} childIds={childIds} />;
      }
      case BlockType.NumberedListBlock: {
        return <NumberedListBlock node={node} childIds={childIds} />;
      }
      case BlockType.ToggleListBlock: {
        return <ToggleListBlock node={node} childIds={childIds} />;
      }
      case BlockType.DividerBlock: {
        return <DividerBlock />;
      }
      case BlockType.CalloutBlock: {
        return <CalloutBlock node={node} childIds={childIds} />;
      }
      case BlockType.CodeBlock:
        return <CodeBlock node={node} />;
      default:
        return <UnSupportedBlock />;
    }
  }, [node, childIds]);

  const className = props.className ? ` ${props.className}` : '';
  if (!node) return null;

  return (
    <div {...props} ref={ref} data-block-id={node.id} className={`relative ${className}`}>
      {renderBlock()}
      <BlockOverlay id={id} />
      {isSelected ? (
        <div className='pointer-events-none absolute inset-0 z-[-1] m-[1px] rounded-[4px] bg-[#E0F8FF]' />
      ) : null}
    </div>
  );
}

const NodeWithErrorBoundary = withErrorBoundary(NodeComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

const UnSupportedBlock = () => {
  return (
    <Alert severity='info' className='mb-2'>
      <p>The current version does not support this Block.</p>
    </Alert>
  );
};

export default React.memo(NodeWithErrorBoundary);
