import React from 'react';

import Editor, { EditorProps } from '@/components/editor/Editor';
import withAppWrapper from '@/components/main/withAppWrapper';

export function mountEditor (props: EditorProps) {
  const AppWrapper = withAppWrapper(() => {
    return (
      <div className={'h-screen w-screen flex flex-col items-center py-20 overflow-y-auto border border-line-divider'}>
        <Editor {...props} />
      </div>
    );
  });

  cy.mount(<AppWrapper />);
}