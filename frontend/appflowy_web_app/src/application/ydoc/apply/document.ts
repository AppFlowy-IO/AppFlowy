import * as Y from 'yjs';
import { CollabOrigin } from '@/application/collab.type';

/**
 * Apply doc state from server to client
 * Note: origin is always remote
 * @param doc local Y.Doc
 * @param state state from server
 */
export function applyDocument(doc: Y.Doc, state: Uint8Array) {
  Y.transact(
    doc,
    () => {
      Y.applyUpdate(doc, state);
    },
    CollabOrigin.Remote
  );
}
