import React from 'react';
import { Block, BlockType } from '$app/interfaces';
import PageBlock from '../PageBlock';
import TextBlock from '../TextBlock';
import HeadingBlock from '../HeadingBlock';
import ListBlock from '../ListBlock';
import CodeBlock from '../CodeBlock';

export default function BlockComponent({ block }: { block: Block }) {
  const renderComponent = () => {
    switch (block.type) {
      case BlockType.PageBlock:
        return <PageBlock block={block} />;
      case BlockType.TextBlock:
        return <TextBlock block={block} />;
      case BlockType.HeadingBlock:
        return <HeadingBlock block={block} />;
      case BlockType.ListBlock:
        return <ListBlock block={block} />;
      case BlockType.CodeBlock:
        return <CodeBlock block={block} />;

      default:
        return null;
    }
  };

  return (
    <div className='relative' data-block-id={block.id}>
      {renderComponent()}
    </div>
  );
}
