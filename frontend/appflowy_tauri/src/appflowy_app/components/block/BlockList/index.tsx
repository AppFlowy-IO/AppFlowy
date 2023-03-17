import React from 'react';
import { BlockListProps, useBlockList, withTextBlockManager } from './BlockList.hooks';
import { withErrorBoundary } from 'react-error-boundary';

import ListFallbackComponent from './ListFallbackComponent';
import BlockListTitle from './BlockListTitle';
import BlockComponent from './BlockComponent';

function BlockList(props: BlockListProps) {
  const { root } = useBlockList(props);

  return (
    <div id='appflowy-block-doc' className='h-[100%] overflow-hidden'>
      <div className='doc-scroller-container flex h-[100%] flex-wrap items-center justify-center overflow-auto px-10'>
        <div className='max-w-screen w-[900px] min-w-0'>
          <BlockListTitle node={root} />
          {root?.children.map((item) => (
            <BlockComponent key={item.id} node={item} className='' />
          ))}
        </div>
      </div>
    </div>
  );
}

const ListWithErrorBoundary = withErrorBoundary(withTextBlockManager(BlockList), {
  FallbackComponent: ListFallbackComponent,
});

export default React.memo(ListWithErrorBoundary);
