import { YSharedRoot } from '@/application/collab.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYArrayEvent(
  _sharedRoot: YSharedRoot,
  _editor: Editor,
  _event: Y.YEvent<Y.Array<string>>
): Operation[] {
  return [];
}
