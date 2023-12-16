import React, { useCallback, useEffect, useRef } from 'react';
import { Editor } from 'src/appflowy_app/components/editor';
import { DocumentHeader } from 'src/appflowy_app/components/document/document_header';
import { useAppSelector } from '$app/stores/store';

export function Document({ id }: { id: string }) {
  const pages = useAppSelector((state) => state.pages.pageMap);

  const getRecentPages = useCallback(async () => {
    return Object.values(pages).map((page) => page);
  }, [pages]);

  const appendTextRef = useRef<((text: string) => void) | null>(null);

  const onSplitTitle = useCallback((splitText: string) => {
    if (appendTextRef.current === null) {
      return;
    }

    const windowSelection = window.getSelection();

    windowSelection?.removeAllRanges();
    appendTextRef.current(splitText);
  }, []);

  useEffect(() => {
    return () => {
      appendTextRef.current = null;
    };
  }, []);

  return (
    <div className={'relative'}>
      <DocumentHeader onSplitTitle={onSplitTitle} pageId={id} />
      <Editor getRecentPages={getRecentPages} appendTextRef={appendTextRef} id={id} />
    </div>
  );
}

export default Document;
