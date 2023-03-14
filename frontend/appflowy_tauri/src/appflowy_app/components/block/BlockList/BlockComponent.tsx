import React, { useEffect, forwardRef, useState } from 'react';
import { BlockCommonProps, BlockType } from '$app/interfaces';
import PageBlock from '../PageBlock';
import TextBlock from '../TextBlock';
import HeadingBlock from '../HeadingBlock';
import ListBlock from '../ListBlock';
import CodeBlock from '../CodeBlock';
import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from './BlockList.hooks';

const BlockComponent = forwardRef(
  (
    {
      node,
      renderChild,
      ...props
    }: { node: TreeNode; renderChild?: (_node: TreeNode) => React.ReactNode } & React.DetailedHTMLProps<
      React.HTMLAttributes<HTMLDivElement>,
      HTMLDivElement
    >,
    ref: React.ForwardedRef<HTMLDivElement>
  ) => {
    const [version, forceUpdate] = useState<number>(0);

    const renderComponent = () => {
      let BlockComponentClass: (_: BlockCommonProps<TreeNode>) => JSX.Element | null;
      switch (node.type) {
        case BlockType.PageBlock:
          BlockComponentClass = PageBlock;
          break;
        case BlockType.TextBlock:
          BlockComponentClass = TextBlock;
          break;
        case BlockType.HeadingBlock:
          BlockComponentClass = HeadingBlock;
          break;
        case BlockType.ListBlock:
          BlockComponentClass = ListBlock;
          break;
        case BlockType.CodeBlock:
          BlockComponentClass = CodeBlock;
          break;
        default:
          break;
      }

      const blockProps: BlockCommonProps<TreeNode> = {
        version,
        node,
      };

      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (BlockComponentClass) {
        return <BlockComponentClass {...blockProps} />;
      }
      return null;
    };

    useEffect(() => {
      node.registerUpdate(() => forceUpdate((prev) => prev + 1));
      return () => {
        node.unregisterUpdate();
      };
    }, []);

    return (
      <div
        ref={ref}
        {...props}
        data-block-id={node.id}
        className={props.className ? `${props.className} relative` : 'relative'}
      >
        {renderComponent()}
        {renderChild ? node.children.map(renderChild) : null}
        <div className='block-overlay'></div>
      </div>
    );
  }
);

const ComponentWithErrorBoundary = withErrorBoundary(BlockComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});
export default React.memo(ComponentWithErrorBoundary);
