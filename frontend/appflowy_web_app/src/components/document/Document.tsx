import { GetViewRowsMap, LoadView, LoadViewMeta, YDoc } from '@/application/collab.type';
import DocumentSkeleton from '@/components/document/DocumentSkeleton';
import { Editor } from '@/components/editor';
import React, { Suspense } from 'react';
import ViewMetaPreview, { ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';

export interface DocumentProps {
  doc: YDoc;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  loadView?: LoadView;
  getViewRowsMap?: GetViewRowsMap;
  viewMeta: ViewMetaProps;
}

export const Document = ({ doc, loadView, navigateToView, loadViewMeta, getViewRowsMap, viewMeta }: DocumentProps) => {
  return (
    <div className={'mb-16 flex h-full w-full flex-col items-center justify-center'}>
      <ViewMetaPreview {...viewMeta} />
      <Suspense fallback={<DocumentSkeleton />}>
        <div className={'mx-16 w-[964px] min-w-0 max-w-full'}>
          <Editor
            loadView={loadView}
            loadViewMeta={loadViewMeta}
            navigateToView={navigateToView}
            getViewRowsMap={getViewRowsMap}
            doc={doc}
            readOnly={true}
          />
        </div>
      </Suspense>
    </div>
  );
};

export default Document;
