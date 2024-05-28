import { YDoc, YjsFolderKey } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import DocumentCover from '@/components/document/document_header/DocumentCover';
import React, { memo, useMemo, useRef, useState } from 'react';

export function DocumentHeader({ viewId, doc }: { viewId: string; doc: YDoc }) {
  const ref = useRef<HTMLDivElement>(null);
  const { view } = useViewSelector(viewId);
  const [textColor, setTextColor] = useState<string>('var(--text-title)');
  const icon = view?.get(YjsFolderKey.icon);
  const iconObject = useMemo(() => {
    try {
      return JSON.parse(icon || '');
    } catch (e) {
      return null;
    }
  }, [icon]);

  return (
    <div ref={ref} className={'document-header mb-[10px] select-none'}>
      <div className={'view-banner relative flex w-full flex-col overflow-hidden'}>
        <DocumentCover onTextColor={setTextColor} doc={doc} />

        <div className={`relative mx-16 w-[964px] min-w-0 max-w-full overflow-visible max-md:mx-4`}>
          <div
            style={{
              position: 'absolute',
              bottom: '100%',
              width: '100%',
            }}
            className={'flex items-center gap-2 px-14 pb-10 text-4xl max-md:px-2 max-md:pb-6 max-sm:text-[7vw]'}
          >
            <div className={`view-icon`}>{iconObject?.value}</div>
            <div className={'flex flex-1 items-center gap-2 overflow-hidden'}>
              <div
                style={{
                  color: textColor,
                }}
                className={'font-bold leading-[1.5em]'}
              >
                {view?.get(YjsFolderKey.name)}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default memo(DocumentHeader);
