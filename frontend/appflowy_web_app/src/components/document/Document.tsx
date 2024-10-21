import { CreateRowDoc, LoadView, LoadViewMeta, YDoc, YjsEditorKey } from '@/application/types';
import EditorSkeleton from '@/components/_shared/skeleton/EditorSkeleton';
import { Editor } from '@/components/editor';
import { EditorVariant } from '@/components/editor/EditorContext';
import React, { Suspense, useCallback } from 'react';
import ViewMetaPreview, { ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';
import { useSearchParams } from 'react-router-dom';

export interface DocumentProps {
  doc: YDoc;
  readOnly: boolean;
  navigateToView?: (viewId: string, blockId?: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  loadView?: LoadView;
  createRowDoc?: CreateRowDoc;
  viewMeta: ViewMetaProps;
  isTemplateThumb?: boolean;
  variant?: EditorVariant;
  onRendered?: () => void;
}

export const Document = ({
  doc,
  readOnly,
  loadView,
  navigateToView,
  loadViewMeta,
  createRowDoc,
  viewMeta,
  isTemplateThumb,
  variant,
  onRendered,
}: DocumentProps) => {
  const [search, setSearch] = useSearchParams();
  const blockId = search.get('blockId') || undefined;

  const onJumpedBlockId = useCallback(() => {
    setSearch(prev => {
      prev.delete('blockId');
      return prev;
    });
  }, [setSearch]);
  const document = doc?.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.document);

  if (!document || !viewMeta.viewId) return null;

  return (
    <div
      style={{
        minHeight: `calc(100vh - 48px)`,
      }}
      className={'flex h-full w-full flex-col items-center'}
    >
      <ViewMetaPreview {...viewMeta} />
      <Suspense fallback={<EditorSkeleton />}>
        <div className={'flex justify-center w-full'}>
          <Editor
            viewId={viewMeta.viewId}
            loadView={loadView}
            loadViewMeta={loadViewMeta}
            navigateToView={navigateToView}
            createRowDoc={createRowDoc}
            readSummary={isTemplateThumb}
            doc={doc}
            readOnly={readOnly}
            jumpBlockId={blockId}
            onJumpedBlockId={onJumpedBlockId}
            variant={variant}
            onRendered={onRendered}
          />
        </div>
      </Suspense>

    </div>
  );
};

export default Document;
