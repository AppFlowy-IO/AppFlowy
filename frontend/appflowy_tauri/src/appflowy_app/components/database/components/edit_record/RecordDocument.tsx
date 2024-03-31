import React from 'react';
import Editor from '$app/components/editor/Editor';

interface Props {
  documentId: string;
}

function RecordDocument({ documentId }: Props) {
  return <Editor disableFocus={true} id={documentId} showTitle={false} />;
}

export default RecordDocument;
