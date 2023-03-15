import React from 'react';
import { BlockListProps, useBlockList, withSelection } from './BlockList.hooks';
import VirtualList from '../../VirtualizedTree';
import { withErrorBoundary } from 'react-error-boundary';

import ListFallbackComponent from './ListFallbackComponent';

function BlockList(props: BlockListProps) {
  const { root } = useBlockList(props);

  return (
    <div id='appflowy-block-doc' className='h-[100%] overflow-hidden'>
      {root && root.children.length > 0 ? (
        <VirtualList
          titleInfo={{
            height: 140,
            component: ({ style }: { style: any }) => (
              <div
                className='doc-title my-[50px] flex h-[40px] text-4xl font-bold'
                style={{
                  ...style,
                  height: undefined,
                  top: 0,
                }}
              >
                {root?.data.title}
              </div>
            ),
          }}
          nodes={root.children}
        />
      ) : null}
    </div>
  );
}

const ListWithErrorBoundary = withErrorBoundary(withSelection(BlockList), {
  FallbackComponent: ListFallbackComponent,
});

export default React.memo(ListWithErrorBoundary);
