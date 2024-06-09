import { withTestingYDoc, withTestingYjsEditor } from './withTestingYjsEditor';
import { yDocToSlateContent } from '../utils/convert';
import { createEditor, Editor } from 'slate';
import { expect } from '@jest/globals';
import * as Y from 'yjs';

function normalizedSlateDoc(doc: Y.Doc) {
  const editor = createEditor();

  const yjsEditor = withTestingYjsEditor(editor, doc);

  editor.children = yDocToSlateContent(doc)?.children ?? [];
  return yjsEditor.children;
}

export async function runCollaborationTest() {
  const doc = withTestingYDoc('1');
  const editor = createEditor();
  const yjsEditor = withTestingYjsEditor(editor, doc);

  // Keep the 'local' editor state before applying run.
  const baseState = Y.encodeStateAsUpdateV2(doc);

  Editor.normalize(editor, { force: true });

  expect(normalizedSlateDoc(doc)).toEqual(yjsEditor.children);

  // Setup remote editor with input base state
  const remoteDoc = new Y.Doc();

  Y.applyUpdateV2(remoteDoc, baseState);
  const remote = withTestingYjsEditor(createEditor(), remoteDoc);

  // Apply changes from 'run'
  Y.applyUpdateV2(remoteDoc, Y.encodeStateAsUpdateV2(yjsEditor.sharedRoot.doc!));

  // Verify remote and editor state are equal
  expect(normalizedSlateDoc(remoteDoc)).toEqual(remote.children);
  expect(yjsEditor.children).toEqual(remote.children);
  expect(normalizedSlateDoc(doc)).toEqual(yjsEditor.children);
}

export function runLocalChangeTest() {
  const doc = withTestingYDoc('1');
  const editor = withTestingYjsEditor(createEditor(), doc);

  editor.connect();

  editor.insertNode(
    {
      type: 'paragraph',
      blockId: '1',
      children: [
        {
          textId: '1',
          type: 'text',
          children: [{ text: 'Hello' }],
        },
      ],
    },
    {
      at: [0],
    }
  );

  editor.apply({
    type: 'set_selection',
    properties: {},
    newProperties: { anchor: { path: [0, 0], offset: 5 }, focus: { path: [0, 0], offset: 5 } },
  });
  // expect(editor.children).toEqual(yDocToSlateContent(doc)?.children);
}
