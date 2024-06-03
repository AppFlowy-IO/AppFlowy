import { Operation, Node } from 'slate';
import * as Y from 'yjs';

export function applySlateOp(ydoc: Y.Doc, slateRoot: Node, op: Operation) {
  console.log('applySlateOp', op);
}
