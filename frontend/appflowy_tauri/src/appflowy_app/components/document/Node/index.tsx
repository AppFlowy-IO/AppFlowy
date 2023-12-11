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
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';
import EquationBlock from '$app/components/document/EquationBlock';
import ImageBlock from '$app/components/document/ImageBlock';
import GridBlock from '$app/components/document/GridBlock';

import { useTranslation } from 'react-i18next';
import BlockDraggable from '$app/components/_shared/BlockDraggable';
import { BlockDraggableType } from '$app_reducers/block-draggable/slice';

function NodeComponent({ id, ...props }: { id: string } & React.HTMLAttributes<HTMLDivElement>) {
  const { node, childIds, isSelected, ref } = useNode(id);

  const renderBlock = useCallback(() => {
    switch (node.type) {
      case BlockType.TextBlock:
        return <TextBlock node={node} childIds={childIds} />;

      case BlockType.HeadingBlock:
        return <HeadingBlock node={node} />;

      case BlockType.TodoListBlock:
        return <TodoListBlock node={node} childIds={childIds} />;

      case BlockType.QuoteBlock:
        return <QuoteBlock node={node} childIds={childIds} />;
      case BlockType.BulletedListBlock:
        return <BulletedListBlock node={node} childIds={childIds} />;

      case BlockType.NumberedListBlock:
        return <NumberedListBlock node={node} childIds={childIds} />;

      case BlockType.ToggleListBlock:
        return <ToggleListBlock node={node} childIds={childIds} />;

      case BlockType.DividerBlock:
        return <DividerBlock />;

      case BlockType.CalloutBlock:
        return <CalloutBlock node={node} childIds={childIds} />;

      case BlockType.CodeBlock:
        return <CodeBlock node={node} />;
      case BlockType.EquationBlock:
        return <EquationBlock node={node} />;
      case BlockType.ImageBlock:
        return <ImageBlock node={node} />;
      case BlockType.GridBlock:
        return <GridBlock node={node} />;
      default:
        return <UnSupportedBlock />;
    }
  }, [node, childIds]);

  const className = props.className ? ` ${props.className}` : '';

  if (!node) return null;

  return (
    <NodeIdContext.Provider value={id}>
      <BlockDraggable
        id={id}
        type={BlockDraggableType.BLOCK}
        getAnchorEl={() => {
          return ref.current?.querySelector(`[data-draggable-anchor="${id}"]`) || null;
        }}
        {...props}
        ref={ref}
        data-block-id={node.id}
        className={className}
      >
        {renderBlock()}
        <BlockOverlay id={id} />
        {isSelected ? (
          <div className='pointer-events-none absolute inset-0 z-[-1] my-[1px] rounded-[4px] bg-content-blue-100' />
        ) : null}
      </BlockDraggable>
    </NodeIdContext.Provider>
  );
}

const NodeWithErrorBoundary = withErrorBoundary(React.memo(NodeComponent), {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

const UnSupportedBlock = () => {
  const { t } = useTranslation();

  return (
    <Alert severity='info' className='mb-2'>
      <p>{t('unSupportBlock')}</p>
    </Alert>
  );
};

export default NodeWithErrorBoundary;
