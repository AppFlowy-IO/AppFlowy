import { YSharedRoot } from '@/application/collab.type';
import * as Y from 'yjs';
import { Editor, Operation } from 'slate';

export function translateYMapEvent(
  _sharedRoot: YSharedRoot,
  _editor: Editor,
  _event: Y.YEvent<Y.Map<unknown>>
): Operation[] {
  return [];
}
