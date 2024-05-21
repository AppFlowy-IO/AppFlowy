import { YSharedRoot } from '@/application/collab.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYTextEvent(sharedRoot: YSharedRoot, editor: Editor, event: Y.YEvent<Y.Text>): Operation[] {
  console.log('translateYTextEvent', sharedRoot, editor, event);
  return [];
}
