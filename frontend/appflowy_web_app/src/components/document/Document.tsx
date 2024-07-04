import { YDoc } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { Editor } from '@/components/editor';
import React, { Suspense } from 'react';
import ViewMetaPreview, { ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';
import Y from 'yjs';

export interface DocumentProps extends ViewMetaProps {
  doc: YDoc;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
  loadView?: (viewId: string) => Promise<YDoc>;
  getViewRowsMap?: (viewId: string, rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
}

export const Document = ({
  doc,
  loadView,
  navigateToView,
  loadViewMeta,
  getViewRowsMap,
  ...viewMeta
}: DocumentProps) => {
  return (
    <div
      style={{
        scrollMarginBottom: '64px',
      }}
      className={'mb-10 flex h-full w-full flex-col items-center justify-center'}
    >
      <ViewMetaPreview {...viewMeta} />
      <Suspense fallback={<ComponentLoading />}>
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
