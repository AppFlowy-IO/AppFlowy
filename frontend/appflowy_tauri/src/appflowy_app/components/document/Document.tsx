import React, { useCallback, useEffect, useRef } from 'react';
import { Editor } from 'src/appflowy_app/components/editor';
import { DocumentHeader } from 'src/appflowy_app/components/document/document_header';

export function Document({ id }: { id: string }) {
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
      <Editor appendTextRef={appendTextRef} id={id} />
    </div>
  );
}

export default Document;
