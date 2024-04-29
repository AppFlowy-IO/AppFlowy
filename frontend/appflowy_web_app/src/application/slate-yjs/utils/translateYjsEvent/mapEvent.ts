import { YSharedRoot } from '@/application/document.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYMapEvent(
  sharedRoot: YSharedRoot,
  editor: Editor,
  event: Y.YEvent<Y.Map<unknown>>
): Operation[] {
  console.log('translateYMapEvent', sharedRoot, editor, event);
  return [];
}
