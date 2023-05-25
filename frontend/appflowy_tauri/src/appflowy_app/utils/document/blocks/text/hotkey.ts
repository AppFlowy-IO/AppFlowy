import isHotkey from 'is-hotkey';
import { Editor, Range } from 'slate';
import { getAfterRangeAt, getBeforeRangeAt, pointInBegin, pointInEnd } from './delta';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';

const HOTKEYS: Record<string, string> = {
  'mod+b': 'bold',
  'mod+i': 'italic',
  'mod+u': 'underline',
  'mod+e': 'code',
  'mod+shift+X': 'strikethrough',
  'mod+shift+S': 'strikethrough',
};

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
