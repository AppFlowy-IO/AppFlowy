import { CollabOrigin } from '@/application/collab.type';
import * as Y from 'yjs';

/**
 * Apply doc state from server to client
 * Note: origin is always remote
 * @param doc local Y.Doc
 * @param state state from server
 */
export function applyYDoc(doc: Y.Doc, state: Uint8Array) {
  Y.transact(
    doc,
    () => {
      try {
        Y.applyUpdate(doc, state);
      } catch (e) {
        console.error('Error applying', doc, e);
        throw e;
      }
    },
    CollabOrigin.Remote
  );
}
