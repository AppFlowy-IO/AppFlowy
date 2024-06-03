import { Operation, Node } from 'slate';
import * as Y from 'yjs';

// transform slate op to yjs op and apply it to ydoc
export function applyToYjs(_ydoc: Y.Doc, _slateRoot: Node, op: Operation) {
  if (op.type === 'set_selection') return;
  console.log('applySlateOp', op);
}
