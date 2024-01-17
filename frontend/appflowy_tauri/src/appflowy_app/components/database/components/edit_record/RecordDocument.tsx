import React from 'react';
import Editor from '$app/components/editor/Editor';

interface Props {
  documentId: string;
}

function RecordDocument({ documentId }: Props) {
  return <Editor id={documentId} showTitle={false} />;
}

export default React.memo(RecordDocument);
