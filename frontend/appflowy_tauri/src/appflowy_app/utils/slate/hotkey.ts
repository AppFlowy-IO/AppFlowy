import isHotkey from 'is-hotkey';
import { toggleFormat } from './format';
import { Editor, Range } from 'slate';
import { getRetainRangeBy, getDelta, getInsertRangeBy } from './text';
import { TextDelta, TextSelection } from '$app/interfaces/document';

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
  const isEnter = event.key === 'Enter';
  return isEnter && editor.selection;
}

export function canHandleBackspaceKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isBackspaceKey = event.key === 'Backspace';
  const selection = editor.selection;
  if (!isBackspaceKey || !selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the beginning of the block
  const { anchor } = selection;
  const isCollapsed = Range.isCollapsed(selection);
  return isCollapsed && anchor.offset === 0 && anchor.path.toString() === '0,0';
}

export function canHandleTabKey(event: React.KeyboardEvent<HTMLDivElement>, _: Editor) {
  return event.key === 'Tab';
}

export function onHandleEnterKey(
  event: React.KeyboardEvent<HTMLDivElement>,
  editor: Editor,
  {
    onSplit,
    onWrap,
  }: {
    onSplit: (...args: [TextDelta[], TextDelta[]]) => Promise<void>;
    onWrap: (newDelta: TextDelta[], selection: TextSelection) => Promise<void>;
  }
) {
  // get the retain content
  const retainRange = getRetainRangeBy(editor);
  const retain = getDelta(editor, retainRange);
  // get the insert content
  const insertRange = getInsertRangeBy(editor);
  const insert = getDelta(editor, insertRange);

  // if the shift key is pressed, break wrap the current node
  if (event.shiftKey || event.ctrlKey || event.altKey) {
    const selection = getSelectionAfterBreakWrap(editor);
    if (!selection) return;
    // insert `\n` after the retain content
    void onWrap([...retain, { insert: '\n' }, ...insert], selection);
    return;
  }

  // retain this node and insert a new node
  void onSplit(retain, insert);
}

function getSelectionAfterBreakWrap(editor: Editor) {
  const selection = editor.selection;
  if (!selection) return;
  const start = Range.start(selection);
  const cursor = { ...start, offset: start.offset + 1 };
  const newSelection = {
    anchor: Object.create(cursor),
    focus: Object.create(cursor),
  } as TextSelection;
  return newSelection;
}
