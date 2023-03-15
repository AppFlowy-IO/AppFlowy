import React from 'react';
import { BlockListProps, useBlockList } from './BlockList.hooks';
import { withErrorBoundary } from 'react-error-boundary';

import ListFallbackComponent from './ListFallbackComponent';
import BlockListTitle from './BlockListTitle';
import BlockComponent from './BlockComponent';

function BlockList(props: BlockListProps) {
  const { root } = useBlockList(props);

  return (
    <div id='appflowy-block-doc' className='h-[100%] overflow-hidden'>
      {root && root.children.length > 0 ? (
        <div className='doc-scroller-container h-[100%] overflow-auto'>
          <div className='flex flex-wrap items-center justify-center px-10'>
            <BlockListTitle node={root} />
            {root.children.map((item) => (
              <BlockComponent key={item.id} node={item} className='max-w-screen w-[900px] min-w-0' />
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}

const ListWithErrorBoundary = withErrorBoundary(BlockList, {
  FallbackComponent: ListFallbackComponent,
});

export default React.memo(ListWithErrorBoundary);
