import isHotkey from 'is-hotkey';
import { toggleFormat } from './format';
import { Editor, Range } from 'slate';
import { getRetainRangeBy, getDelta, getInsertRangeBy } from './text';
import { TextDelta } from '$app/interfaces/document';

const HOTKEYS: Record<string, string> = {
  'mod+b': 'bold',
  'mod+i': 'italic',
  'mod+u': 'underline',
  'mod+e': 'code',
  'mod+shift+X': 'strikethrough',
  'mod+shift+S': 'strikethrough',
};

export function triggerHotkey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  for (const hotkey in HOTKEYS) {
    if (isHotkey(hotkey, event)) {
      event.preventDefault();
      const format = HOTKEYS[hotkey];
      toggleFormat(editor, format);
    }
  }
}

export function canHandleEnterKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isEnter = event.key === 'Enter' && !event.shiftKey && !event.ctrlKey && !event.altKey;
  if (!isEnter || !editor.selection) {
    return false;
  }
  return true;
}

export function canHandleBackspaceKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isBackspaceKey = event.key === 'Backspace' && !event.shiftKey && !event.ctrlKey && !event.altKey;
  if (!isBackspaceKey || !editor.selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the beginning of the block
  const { anchor } = editor.selection;
  const isCollapsed = Range.isCollapsed(editor.selection);
  return isCollapsed && anchor.offset === 0 && anchor.path.toString() === '0,0';
}

export function canHandleTabKey(event: React.KeyboardEvent<HTMLDivElement>, _: Editor) {
  return event.key === 'Tab' && !event.shiftKey && !event.ctrlKey && !event.altKey;
}

export function onHandleEnterKey(
  event: React.KeyboardEvent<HTMLDivElement>,
  editor: Editor,
  onEnter: (...args: [TextDelta[], TextDelta[]]) => Promise<void>
) {
  // get the retain content
  const retainRange = getRetainRangeBy(editor);
  const retain = getDelta(editor, retainRange);
  // get the insert content
  const insertRange = getInsertRangeBy(editor);
  const insert = getDelta(editor, insertRange);
  void (async () => {
    // retain this node and insert a new node
    await onEnter(retain, insert);
  })();
}
