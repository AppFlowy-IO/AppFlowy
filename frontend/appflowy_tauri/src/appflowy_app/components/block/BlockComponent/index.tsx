import React, { forwardRef } from 'react';
import { BlockCommonProps, BlockType } from '$app/interfaces';
import PageBlock from '../PageBlock';
import TextBlock from '../TextBlock';
import HeadingBlock from '../HeadingBlock';
import ListBlock from '../ListBlock';
import CodeBlock from '../CodeBlock';
import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { withErrorBoundary } from 'react-error-boundary';
import { ErrorBoundaryFallbackComponent } from '../BlockList/BlockList.hooks';
import { useBlockComponent } from './BlockComponet.hooks';

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
    const { myRef, className, version, isSelected } = useBlockComponent({
      node,
    });

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

    return (
      <div
        ref={(el: HTMLDivElement | null) => {
          myRef.current = el;
          if (typeof ref === 'function') {
            ref(el);
          } else if (ref) {
            ref.current = el;
          }
        }}
        {...props}
        data-block-id={node.id}
        data-block-selected={isSelected}
        className={props.className ? `${props.className} ${className}` : className}
      >
        {renderComponent()}
        {renderChild ? node.children.map(renderChild) : null}
        <div className='block-overlay'></div>
        {isSelected ? <div className='pointer-events-none absolute inset-0 z-[-1] rounded-[4px] bg-[#E0F8FF]' /> : null}
      </div>
    );
  }
);

const ComponentWithErrorBoundary = withErrorBoundary(BlockComponent, {
  FallbackComponent: ErrorBoundaryFallbackComponent,
});
export default React.memo(ComponentWithErrorBoundary);
