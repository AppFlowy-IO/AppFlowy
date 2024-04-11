import { YSharedRoot } from '@/application/document.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYTextEvent (sharedRoot: YSharedRoot,
  editor: Editor,
  event: Y.YEvent<Y.Text>): Operation[] {
  return [];
}