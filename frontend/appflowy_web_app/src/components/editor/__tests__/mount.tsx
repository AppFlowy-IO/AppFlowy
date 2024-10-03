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

export const moveToLineStart = (lineIndex: number) => {
  const selector = '[role="textbox"]';

  cy.get(selector).as('targetBlock');

  if (lineIndex === 0) {
    cy.get('@targetBlock').type('{movetostart}').wait(50);
  } else {
    cy.get('@targetBlock').type('{movetostart}').type('{downarrow}'.repeat(lineIndex))
      .wait(50);
  }
};

export const moveAndEnter = (lineIndex: number, moveCount: number) => {
  moveToLineStart(lineIndex);
  // Move the cursor with right arrow key and batch the movement
  const batchSize = 5;
  const batches = Math.ceil(moveCount / batchSize);

  for (let i = 0; i < batches; i++) {
    const remainingMoves = Math.min(batchSize, moveCount - i * batchSize);

    cy.get('@targetBlock')
      .type('{rightarrow}'.repeat(remainingMoves))
      .wait(50);
  }

  cy.get('@targetBlock').type('{enter}');
};