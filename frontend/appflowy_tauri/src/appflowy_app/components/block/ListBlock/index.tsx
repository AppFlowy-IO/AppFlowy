import React from 'react';
import { Block } from '$app/interfaces';
import BlockComponent from '../BlockList/BlockComponent';
import TextBlock from '../TextBlock';

export default function ListBlock({ block }: { block: Block }) {
  const renderChildren = () => {
    return block.children?.map((item) => (
      <li key={item.id}>
        <BlockComponent block={item} />
      </li>
    ));
  };

  return (
    <div className={`${block.data.type === 'ul' ? 'bulleted_list' : 'number_list'} flex`}>
      <li className='w-[24px]' />
      <div>
        <TextBlock
          block={{
            ...block,
            children: [],
          }}
        />
        {renderChildren()}
      </div>
    </div>
  );
}
