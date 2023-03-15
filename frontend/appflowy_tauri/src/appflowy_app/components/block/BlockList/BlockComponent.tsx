import React, { useContext, useEffect, useRef } from 'react';
import { BlockType } from '$app/interfaces';
import PageBlock from '../PageBlock';
import TextBlock from '../TextBlock';
import HeadingBlock from '../HeadingBlock';
import ListBlock from '../ListBlock';
import CodeBlock from '../CodeBlock';
import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from './BlockList.hooks';
import { BlockContext } from '@/appflowy_app/utils/block';

function BlockComponent({
  node,
  ...props
}: { node: TreeNode } & React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>) {
  const { blockEditor } = useContext(BlockContext);

  const ref = useRef<HTMLDivElement>(null);

  const renderComponent = () => {
    switch (node.type) {
      case BlockType.PageBlock:
        return <PageBlock node={node} />;
      case BlockType.TextBlock:
        return <TextBlock node={node} />;
      case BlockType.HeadingBlock:
        return <HeadingBlock node={node} />;
      case BlockType.ListBlock:
        return <ListBlock node={node} />;
      case BlockType.CodeBlock:
        return <CodeBlock node={node} />;
      default:
        return null;
    }
  };

  useEffect(() => {
    if (!ref.current) return;

    const observe = blockEditor?.renderTree.observeNode(node.id, ref.current);

    return () => {
      observe?.disconnect();
    };
  }, []);

  return (
    <div ref={ref} {...props} data-block-id={node.id} className={props.className + ' relative'}>
      {renderComponent()}
      {props.children}
      <div className='block-overlay'></div>
    </div>
  );
}

const ComponentWithErrorBoundary = withErrorBoundary(BlockComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});
export default React.memo(ComponentWithErrorBoundary);
