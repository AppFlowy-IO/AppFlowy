import React, { memo } from 'react';
import { EditorProps } from '../../application/document/document.types';

import { CollaborativeEditor } from '$app/components/editor/components/editor';
import { EditorIdProvider } from '$app/components/editor/Editor.hooks';
import './editor.scss';
import withErrorBoundary from '$app/components/_shared/error_boundary/withError';

export function Editor(props: EditorProps) {
  return (
    <div className={'appflowy-editor relative'}>
      <EditorIdProvider value={props.id}>
        <CollaborativeEditor {...props} />
      </EditorIdProvider>
    </div>
  );
}

export default withErrorBoundary(memo(Editor));
