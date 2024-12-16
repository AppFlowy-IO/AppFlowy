import { appendFirstEmptyParagraph } from '@/application/slate-yjs/utils/yjsOperations';
import {
  ViewComponentProps,
  YjsEditorKey, YSharedRoot,
} from '@/application/types';
import EditorSkeleton from '@/components/_shared/skeleton/EditorSkeleton';
import { Editor } from '@/components/editor';
import React, { Suspense, useCallback, useRef } from 'react';
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
    onRendered,
  } = props;
  const blockId = search.get('blockId') || undefined;

  const onJumpedBlockId = useCallback(() => {
    setSearch(prev => {
      prev.delete('blockId');
      return prev;
    });
  }, [setSearch]);
  const document = doc?.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.document);

  const handleEnter = useCallback((text: string) => {
    if (!doc) return;
    const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

    appendFirstEmptyParagraph(sharedRoot, text);
  }, [doc]);

  const ref = useRef<HTMLDivElement>(null);

  const handleRendered = useCallback(() => {
    if (onRendered) {
      onRendered();
    }

    const el = ref.current;

    if (!el) return;

    const scrollElement = el.closest('.MuiPaper-root');

    if (!scrollElement) {
      el.style.minHeight = `calc(100vh - 48px)`;
      return;
    }

    el.style.minHeight = `${scrollElement?.clientHeight - 64}px`;
  }, [onRendered]);

  if (!document || !viewMeta.viewId) return null;

  return (
    <div
      ref={ref}
      className={'flex h-full w-full flex-col items-center'}
    >
      <ViewMetaPreview
        {...viewMeta}
        readOnly={readOnly}
        updatePage={updatePage}
        onEnter={readOnly ? undefined : handleEnter}
        maxWidth={988}
      />
      <Suspense fallback={<EditorSkeleton/>}>
        <div className={'flex justify-center w-full'}>
          <Editor
            viewId={viewMeta.viewId}
            readSummary={isTemplateThumb}
            jumpBlockId={blockId}
            onJumpedBlockId={onJumpedBlockId}
            onRendered={handleRendered}
            {...props}
          />
        </div>
      </Suspense>

    </div>
  );
};

export default Document;
