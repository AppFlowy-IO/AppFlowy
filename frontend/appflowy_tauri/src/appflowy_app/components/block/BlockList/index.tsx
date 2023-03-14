import BlockComponent from './BlockComponent';
import React from 'react';
import { BlockListProps, useBlockList, withSelection } from './BlockList.hooks';

function BlockList(props: BlockListProps) {
  const { root } = useBlockList(props);

  return (
    <div className='min-x-[0%] p-lg w-[900px] max-w-[100%]'>
      <div className='my-[50px] flex px-14 text-4xl font-bold'>{root?.data.title}</div>
      <div className='px-14'>
        {root && root.children.length > 0
          ? root.children.map((node) => <BlockComponent key={node.id} node={node} />)
          : null}
      </div>
    </div>
  );
}

export default React.memo(withSelection(BlockList));
