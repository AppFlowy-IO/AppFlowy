import { YSharedRoot } from '@/application/collab.type';
import { translateYArrayEvent } from '@/application/slate-yjs/utils/translateYjsEvent/arrayEvent';
import { translateYMapEvent } from '@/application/slate-yjs/utils/translateYjsEvent/mapEvent';
import { Editor, Operation } from 'slate';
import * as Y from 'yjs';
import { translateYTextEvent } from 'src/application/slate-yjs/utils/translateYjsEvent/textEvent';

/**
 * Translate a yjs event into slate operations. The editor state has to match the
 * yText state before the event occurred.
 *
 * @param sharedType
 * @param op
 */
export function translateYjsEvent(sharedRoot: YSharedRoot, editor: Editor, event: Y.YEvent<YSharedRoot>): Operation[] {
  console.log('translateYjsEvent', event);
  if (event instanceof Y.YMapEvent) {
    return translateYMapEvent(sharedRoot, editor, event);
  }

  if (event instanceof Y.YTextEvent) {
    return translateYTextEvent(sharedRoot, editor, event);
  }

  if (event instanceof Y.YArrayEvent) {
    return translateYArrayEvent(sharedRoot, editor, event);
  }

  throw new Error('Unexpected Y event type');
}
