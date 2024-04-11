import * as Y from 'yjs';
import { CollabOrigin } from '@/application/collab.type';

/**
 * Apply doc state from server to client
 * Note: origin is always remote
 * @param doc local Y.Doc
 * @param state state from server
 */
export function applyDocument (doc: Y.Doc, state: Uint8Array) {
  const stateVector = Y.encodeStateVector(doc);
  const diff = Y.diffUpdate(state, stateVector);

  const doc1 = new Y.Doc();

  Y.applyUpdate(doc1, state);
  console.log('doc', doc1.getMap('data').toJSON());
  const diff1 = Y.diffUpdate(state, Y.encodeStateVector(doc));

  console.log(diff1);
  
  Y.transact(doc, () => {
    Y.applyUpdate(doc, diff);
  }, CollabOrigin.Remote);
}