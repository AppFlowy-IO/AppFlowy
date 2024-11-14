import {
  ViewComponentProps,
  YjsEditorKey,
} from '@/application/types';
import EditorSkeleton from '@/components/_shared/skeleton/EditorSkeleton';
import { Editor } from '@/components/editor';
import React, { Suspense, useCallback } from 'react';
import ViewMetaPreview from '@/components/view-meta/ViewMetaPreview';
import { useSearchParams } from 'react-router-dom';

export type DocumentProps = ViewComponentProps;

export const Document = (props: DocumentProps) => {
  const [search, setSearch] = useSearchParams();
  const {
    doc,
    readOnly,
    viewMeta,
    isTemplateThumb,
    updatePage,
  } = props;
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
      <ViewMetaPreview
        {...viewMeta}
        readOnly={readOnly}
        updatePage={updatePage}
      />
      <Suspense fallback={<EditorSkeleton />}>
        <div className={'flex justify-center w-full'}>
          <Editor
            viewId={viewMeta.viewId}
            readSummary={isTemplateThumb}
            jumpBlockId={blockId}
            onJumpedBlockId={onJumpedBlockId}
            {...props}
          />
        </div>
      </Suspense>

    </div>
  );
};

export default Document;
