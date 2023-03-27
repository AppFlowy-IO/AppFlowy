import React, { useCallback } from 'react';
import { useNode } from './Node.hooks';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../_shared/ErrorBoundaryFallbackComponent';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import TextBlock from '../TextBlock';
import { TextDelta } from '@/appflowy_app/interfaces/document';

function NodeComponent({ id, ...props }: { id: string } & React.HTMLAttributes<HTMLDivElement>) {
  const { node, childIds, delta, isSelected, ref } = useNode(id);

  console.log('=====', id);
  const renderBlock = useCallback((_props: { node: Node; childIds?: string[]; delta?: TextDelta[] }) => {
    switch (_props.node.type) {
      case 'text':
        if (!_props.delta) return null;
        return <TextBlock {..._props} delta={_props.delta} />;
      default:
        break;
    }
  }, []);

  if (!node) return null;

  return (
    <div {...props} ref={ref} data-block-id={node.id} className={`relative my-[2px] px-[2px] ${props.className}`}>
      {renderBlock({
        node,
        childIds,
        delta,
      })}
      <div className='block-overlay' />
      {isSelected ? <div className='pointer-events-none absolute inset-0 z-[-1] rounded-[4px] bg-[#E0F8FF]' /> : null}
    </div>
  );
}

const NodeWithErrorBoundary = withErrorBoundary(NodeComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});

export default React.memo(NodeWithErrorBoundary);
