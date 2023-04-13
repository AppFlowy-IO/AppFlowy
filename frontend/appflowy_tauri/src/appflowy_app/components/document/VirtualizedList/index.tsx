import React from 'react';
import { useVirtualizedList } from './VirtualizedList.hooks';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import DocumentTitle from '../DocumentTitle';
import Overlay from '../Overlay';

export default function VirtualizedList({
  childIds,
  node,
  renderNode,
}: {
  childIds: string[];
  node: Node;
  renderNode: (nodeId: string) => JSX.Element;
}) {
  const { virtualize, parentRef } = useVirtualizedList(childIds.length);
  const virtualItems = virtualize.getVirtualItems();

  return (
    <>
      <div
        ref={parentRef}
        className={`doc-scroller-container flex h-[100%] flex-wrap justify-center overflow-auto px-20`}
      >
        <div
          className='doc-body max-w-screen w-[900px] min-w-0'
          style={{
            height: virtualize.getTotalSize(),
            position: 'relative',
          }}
        >
          {node && childIds && virtualItems.length ? (
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
                const id = childIds[virtualRow.index];
                return (
                  <div className='p-[1px]' key={id} data-index={virtualRow.index} ref={virtualize.measureElement}>
                    {virtualRow.index === 0 ? <DocumentTitle id={node.id} /> : null}
                    {renderNode(id)}
                  </div>
                );
              })}
            </div>
          ) : null}
        </div>
      </div>
      {parentRef.current ? <Overlay container={parentRef.current} /> : null}
    </>
  );
}
