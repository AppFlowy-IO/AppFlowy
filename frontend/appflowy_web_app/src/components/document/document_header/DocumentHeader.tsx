import { YDoc, YjsFolderKey } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import DocumentCover from '@/components/document/document_header/DocumentCover';
import React, { memo, useMemo, useRef } from 'react';

export function DocumentHeader({ viewId, doc }: { viewId: string; doc: YDoc }) {
  const ref = useRef<HTMLDivElement>(null);
  const { view } = useViewSelector(viewId);

  const icon = view?.get(YjsFolderKey.icon);
  const iconObject = useMemo(() => {
    try {
      return JSON.parse(icon || '');
    } catch (e) {
      return null;
    }
  }, [icon]);

  return (
    <div ref={ref} className={'document-header select-none'}>
      <div className={'flex flex-col justify-end'}>
        <div className={'view-banner flex w-full flex-col overflow-hidden'}>
          <DocumentCover doc={doc} />

          <div className={`relative min-h-[65px] w-[964px] min-w-0 max-w-full px-16 pt-10 max-md:px-4`}>
            <div
              style={{
                position: 'relative',
                bottom: '50%',
              }}
            >
              <div className={`view-icon`}>{iconObject?.value}</div>
            </div>
            <div className={'py-2'}></div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default memo(DocumentHeader);
