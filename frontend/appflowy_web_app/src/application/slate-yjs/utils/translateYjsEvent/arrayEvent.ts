import { YSharedRoot } from '@/application/document.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYArrayEvent(
  sharedRoot: YSharedRoot,
  editor: Editor,
  event: Y.YEvent<Y.Array<string>>
): Operation[] {
  console.log('translateYArrayEvent', sharedRoot, editor, event);
  return [];
}
