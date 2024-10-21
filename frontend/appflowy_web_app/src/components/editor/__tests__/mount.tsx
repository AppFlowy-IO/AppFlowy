import { DocumentTest, FromBlockJSON } from 'cypress/support/document';
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

export const moveCursor = (lineIndex: number, charIndex: number) => {
  moveToLineStart(lineIndex);
  // Move the cursor with right arrow key and batch the movement
  const batchSize = 1;
  const batches = Math.ceil(charIndex / batchSize);

  for (let i = 0; i < batches; i++) {
    const remainingMoves = Math.min(batchSize, charIndex - i * batchSize);

    cy.get('@targetBlock')
      .type('{rightarrow}'.repeat(remainingMoves))
      .wait(20);
  }
};

export const moveAndEnter = (lineIndex: number, moveCount: number) => {
  moveToLineStart(lineIndex);
  // Move the cursor with right arrow key and batch the movement
  moveCursor(lineIndex, moveCount);

  cy.get('@targetBlock').type('{enter}');
};

export const initialEditorTest = () => {
  let documentTest: DocumentTest;

  const initializeEditor = (data: FromBlockJSON[]) => {
    documentTest = new DocumentTest();
    documentTest.fromJSON(data);
    mountEditor({ readOnly: false, doc: documentTest.doc, viewId: 'test' });
    cy.get('[role="textbox"]').should('exist');
  };

  const assertJSON = (expectedJSON: FromBlockJSON[]) => {
    cy.wrap(null).then(() => {
      const finalJSON = documentTest.toJSON();

      expect(finalJSON).to.deep.equal(expectedJSON);
    });
  };

  return {
    initializeEditor,
    assertJSON,
  };

};