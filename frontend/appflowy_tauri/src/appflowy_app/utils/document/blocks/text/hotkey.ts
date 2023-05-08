import isHotkey from 'is-hotkey';
import { toggleFormat } from './format';
import { Editor, Range } from 'slate';
import { clonePoint, getAfterRangeAt, getBeforeRangeAt, getDelta, pointInBegin, pointInEnd } from './delta';
import { SelectionPoint, TextDelta, TextSelection } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';

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
  const isBackspaceKey = isHotkey('backspace', event);
  const selection = editor.selection;

  if (!isBackspaceKey || !selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the beginning of the block
  const isCollapsed = Range.isCollapsed(selection);
  return isCollapsed && pointInBegin(editor, selection);
}

export function canHandleTabKey(event: React.KeyboardEvent<HTMLDivElement>, _: Editor) {
  return isHotkey('tab', event);
}

export function canHandleUpKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isUpKey = event.key === keyBoardEventKeyMap.Up;
  const selection = editor.selection;
  if (!isUpKey || !selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the first line of the block
  const isCollapsed = Range.isCollapsed(selection);

  const beforeString = Editor.string(editor, getBeforeRangeAt(editor, selection));
  const isTopEdge = !beforeString.includes('\n');

  return isCollapsed && isTopEdge;
}

export function canHandleDownKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isDownKey = event.key === keyBoardEventKeyMap.Down;
  const selection = editor.selection;
  if (!isDownKey || !selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the last line of the block
  const isCollapsed = Range.isCollapsed(selection);

  const afterString = Editor.string(editor, getAfterRangeAt(editor, selection));
  const isBottomEdge = !afterString.includes('\n');

  return isCollapsed && isBottomEdge;
}

export function canHandleLeftKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isLeftKey = event.key === keyBoardEventKeyMap.Left;
  const selection = editor.selection;
  if (!isLeftKey || !selection) {
    return false;
  }

  // It should be handled if the selection is collapsed and the cursor is at the beginning of the block
  const isCollapsed = Range.isCollapsed(selection);

  return isCollapsed && pointInBegin(editor, selection);
}

export function canHandleRightKey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isRightKey = event.key === keyBoardEventKeyMap.Right;
  const selection = editor.selection;
  if (!isRightKey || !selection) {
    return false;
  }
  // It should be handled if the selection is collapsed and the cursor is at the end of the block
  const isCollapsed = Range.isCollapsed(selection);
  return isCollapsed && pointInEnd(editor, selection);
}

export function onHandleEnterKey(
  event: React.KeyboardEvent<HTMLDivElement>,
  editor: Editor,
  {
    onSplit,
    onWrap,
  }: {
    onSplit: (...args: [TextDelta[], TextDelta[]]) => Promise<void>;
    onWrap: (newDelta: TextDelta[], _selection: TextSelection) => Promise<void>;
  }
) {
  const selection = editor.selection;
  if (!selection) return;
  // get the retain content
  const retainRange = getBeforeRangeAt(editor, selection);
  const retain = getDelta(editor, retainRange);
  // get the insert content
  const insertRange = getAfterRangeAt(editor, selection);
  const insert = getDelta(editor, insertRange);

  // if the shift key is pressed, break wrap the current node
  if (isHotkey('shift+enter', event)) {
    const newSelection = getSelectionAfterBreakWrap(editor);
    if (!newSelection) return;

    // insert `\n` after the retain content
    void onWrap([...retain, { insert: '\n' }, ...insert], newSelection);
    return;
  }

  // if the enter key is pressed, split the current node
  if (isHotkey('enter', event)) {
    // retain this node and insert a new node
    void onSplit(retain, insert);
    return;
  }

  // other cases, do nothing
  return;
}

function getSelectionAfterBreakWrap(editor: Editor) {
  const selection = editor.selection;
  if (!selection) return;
  const start = Range.start(selection);
  const cursor = { path: start.path, offset: start.offset + 1 } as SelectionPoint;
  const newSelection = {
    anchor: clonePoint(cursor),
    focus: clonePoint(cursor),
  } as TextSelection;
  return newSelection;
}
