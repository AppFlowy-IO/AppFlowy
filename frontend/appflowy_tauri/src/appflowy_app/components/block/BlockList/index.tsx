import React from 'react';
import { BlockListProps, useBlockList, withTextBlockManager } from './BlockList.hooks';
import { withErrorBoundary } from 'react-error-boundary';
import ListFallbackComponent from './ListFallbackComponent';
import BlockListTitle from './BlockListTitle';
import BlockComponent from '../BlockComponent';
import BlockSelection from '../BlockSelection';

function BlockList(props: BlockListProps) {
  const { root, rowVirtualizer, parentRef, blockEditor } = useBlockList(props);

  const virtualItems = rowVirtualizer.getVirtualItems();
  return (
    <div id='appflowy-block-doc' className='h-[100%] overflow-hidden'>
      <div
        ref={parentRef}
        className={`doc-scroller-container flex h-[100%] flex-wrap items-center justify-center overflow-auto px-20`}
      >
        <div
          className='doc-body max-w-screen w-[900px] min-w-0'
          style={{
            height: rowVirtualizer.getTotalSize(),
            position: 'relative',
          }}
        >
          {root && virtualItems.length ? (
            <div
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                transform: `translateY(${virtualItems[0].start || 0}px)`,
              }}
            >
              {virtualItems.map((virtualRow) => {
                const id = root.children[virtualRow.index].id;
                return (
                  <div className='p-[1px]' key={id} data-index={virtualRow.index} ref={rowVirtualizer.measureElement}>
                    {virtualRow.index === 0 ? <BlockListTitle node={root} /> : null}
                    <BlockComponent node={root.children[virtualRow.index]} />
                  </div>
                );
              })}
            </div>
          ) : null}
        </div>
      </div>
      {parentRef.current ? <BlockSelection blockEditor={blockEditor} container={parentRef.current} /> : null}
    </div>
  );
}

const ListWithErrorBoundary = withErrorBoundary(withTextBlockManager(BlockList), {
  FallbackComponent: ListFallbackComponent,
});

export default React.memo(ListWithErrorBoundary);
