import React, { useCallback } from 'react';
import { useAppSelector } from '$app/stores/store';
import Editor from '$app/components/editor/Editor';

interface Props {
  documentId: string;
}

function RecordDocument({ documentId }: Props) {
  const pages = useAppSelector((state) => state.pages.pageMap);

  const getRecentPages = useCallback(async () => {
    return Object.values(pages).map((page) => page);
  }, [pages]);

  return <Editor getRecentPages={getRecentPages} id={documentId} />;
}

export default React.memo(RecordDocument);
