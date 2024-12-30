import { CollabOrigin } from '@/application/types';
import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';
import { generateId, insertBlock, withTestingYDoc, withTestingYjsEditor } from './withTestingYjsEditor';
import { createEditor } from 'slate';
import { expect } from '@jest/globals';
import * as Y from 'yjs';

export async function runApplyRemoteEventsTest() {
  const pageId = generateId();
  const remoteDoc = withTestingYDoc(pageId);
  const remote = withTestingYjsEditor(createEditor(), remoteDoc);

  const localDoc = new Y.Doc();

  Y.applyUpdateV2(localDoc, Y.encodeStateAsUpdateV2(remoteDoc));
  const editor = withTestingYjsEditor(createEditor(), localDoc);

  editor.connect();
  expect(editor.children).toEqual(remote.children);

  // update remote doc
  const id = generateId();

  const { applyDelta } = insertBlock({
    doc: remoteDoc,
    blockObject: {
      id,
      ty: 'paragraph',
      relation_id: id,
      text_id: id,
      data: JSON.stringify({ level: 1 }),
    },
  });

  applyDelta([{ insert: 'Hello ' }, { insert: 'World', attributes: { bold: true } }]);

  remote.children = yDocToSlateContent(remoteDoc)?.children ?? [];

  // apply remote changes to local doc
  Y.transact(
    localDoc,
    () => {
      Y.applyUpdateV2(localDoc, Y.encodeStateAsUpdateV2(remoteDoc));
    },
    CollabOrigin.Remote
  );

  expect(editor.children).toEqual(remote.children);
}
