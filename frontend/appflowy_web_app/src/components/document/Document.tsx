import { GetViewRowsMap, LoadView, LoadViewMeta, YDoc } from '@/application/types';
import DocumentSkeleton from '@/components/_shared/skeleton/DocumentSkeleton';
import { Editor } from '@/components/editor';
import React, { Suspense, useCallback } from 'react';
import ViewMetaPreview, { ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';
import { useSearchParams } from 'react-router-dom';

export interface DocumentProps {
  doc: YDoc;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  loadView?: LoadView;
  getViewRowsMap?: GetViewRowsMap;
  viewMeta: ViewMetaProps;
  isTemplateThumb?: boolean;
}

export const Document = ({
  doc,
  loadView,
  navigateToView,
  loadViewMeta,
  getViewRowsMap,
  viewMeta,
  isTemplateThumb,
}: DocumentProps) => {
  const [search, setSearch] = useSearchParams();
  const blockId = search.get('blockId') || undefined;

  const onJumpedBlockId = useCallback(() => {
    setSearch(prev => {
      prev.delete('blockId');
      return prev;
    });
  }, [setSearch]);

  return (
    <div style={{
      minHeight: `calc(100vh - 48px)`,
    }} className={'mb-16 flex h-full w-full flex-col items-center'}
    >
      <ViewMetaPreview {...viewMeta} />
      <Suspense fallback={<DocumentSkeleton />}>
        <div className={'flex justify-center w-full'}>
          <Editor
            loadView={loadView}
            loadViewMeta={loadViewMeta}
            navigateToView={navigateToView}
            getViewRowsMap={getViewRowsMap}
            readSummary={isTemplateThumb}
            doc={doc}
            readOnly={true}
            jumpBlockId={blockId}
            onJumpedBlockId={onJumpedBlockId}
          />
        </div>
      </Suspense>

    </div>
  );
};

export default Document;
