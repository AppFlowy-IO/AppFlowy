import React from 'react';
import { BlockType, TreeNodeImp } from '$app/interfaces';
import PageBlock from '../PageBlock';
import TextBlock from '../TextBlock';
import HeadingBlock from '../HeadingBlock';
import ListBlock from '../ListBlock';
import CodeBlock from '../CodeBlock';

function BlockComponent({
  node,
  ...props
}: { node: TreeNodeImp } & React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>) {
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

  return (
    <div className='relative' data-block-id={node.id} {...props}>
      {renderComponent()}
      {props.children}
      <div className='block-overlay'></div>
    </div>
  );
}

export default React.memo(BlockComponent);
