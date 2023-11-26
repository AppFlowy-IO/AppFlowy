import { useVirtualizedList } from './VirtualizedList.hooks';
import DocumentTitle from '../DocumentTitle';
import Overlay from '../Overlay';
import { Node } from '$app/interfaces/document';

import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { ContainerType, useContainerType } from '$app/hooks/document.hooks';
import { useCallback } from 'react';

export default function VirtualizedList({
  childIds,
  node,
  renderNode,
  getDocumentTitle,
}: {
  childIds: string[];
  node: Node;
  renderNode: (nodeId: string) => JSX.Element;
  getDocumentTitle?: () => React.ReactNode;
}) {
  const { virtualize, parentRef } = useVirtualizedList(childIds.length + 1);
  const virtualItems = virtualize.getVirtualItems();
  const { docId } = useSubscribeDocument();
  const containerType = useContainerType();

  const isDocumentPage = containerType === ContainerType.DocumentPage;

  const renderDocumentTitle = useCallback(() => {
    if (getDocumentTitle) {
      return getDocumentTitle();
    }

    return <DocumentTitle id={node.id} />;
  }, [getDocumentTitle, node.id]);

  return (
    <>
      <div
        ref={parentRef}
        id={`appflowy-scroller_${docId}`}
        className={`doc-scroller-container flex h-[100%] flex-wrap justify-center overflow-auto px-20`}
      >
        <div
          className={`doc-body ${isDocumentPage ? 'max-w-screen w-[900px] min-w-0' : 'w-full'}`}
          style={{
            height: virtualize.getTotalSize(),
            position: 'relative',
          }}
        >
          {node && childIds && virtualItems.length ? (
            <div
              className={'doc-body-inner'}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                transform: `translateY(${virtualItems[0].start || 0}px)`,
              }}
            >
              {virtualItems.map((virtualRow) => {
                const isDocumentTitle = virtualRow.index === 0;
                const id = isDocumentTitle ? node.id : childIds[virtualRow.index - 1];

                return (
                  <div
                    className={isDocumentTitle ? '' : 'pt-[0.5px]'}
                    key={id}
                    data-index={virtualRow.index}
                    ref={virtualize.measureElement}
                  >
                    {isDocumentTitle ? renderDocumentTitle() : renderNode(id)}
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
