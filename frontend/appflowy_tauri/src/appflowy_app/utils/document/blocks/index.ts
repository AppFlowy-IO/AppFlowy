import { Editor } from 'slate';
import {
  BulletListBlockData,
  HeadingBlockData,
  NumberedListBlockData,
  TodoListBlockData,
  ToggleListBlockData,
} from '$app/interfaces/document';
import { getBeforeRangeAt } from '$app/utils/document/slate/text';
import { getDeltaAfterSelection } from '$app/utils/document/blocks/common';

/**
 * get heading data from editor, only support markdown
 * @param editor
 */
export function getHeadingDataFromEditor(editor: Editor): HeadingBlockData | undefined {
  const selection = editor.selection;
  if (!selection) return;
  const hashTags = Editor.string(editor, getBeforeRangeAt(editor, selection));
  const level = hashTags.match(/#/g)?.length;
  if (!level) return;
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    level,
    delta,
  };
}

/**
 * get quote data from editor, only support markdown
 * @param editor
 */
export function getQuoteDataFromEditor(editor: Editor) {
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    size: 'default',
  };
}

/**
 * get todo_list data from editor, only support markdown
 * @param editor
 */
export function getTodoListDataFromEditor(editor: Editor): TodoListBlockData | undefined {
  const selection = editor.selection;
  if (!selection) return;
  const hashTags = Editor.string(editor, getBeforeRangeAt(editor, selection));
  const checked = hashTags.match(/x/g)?.length;
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    checked: !!checked,
  };
}

/**
 * get bulleted_list data from editor, only support markdown
 * @param editor
 */
export function getBulletedDataFromEditor(editor: Editor): BulletListBlockData | undefined {
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    format: 'default',
  };
}

/**
 * get numbered_list data from editor, only support markdown
 * @param editor
 */
export function getNumberedListDataFromEditor(editor: Editor): NumberedListBlockData | undefined {
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    format: 'default',
  };
}

/**
 * get toggle_list data from editor, only support markdown
 */
export function getToggleListDataFromEditor(editor: Editor): ToggleListBlockData | undefined {
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    collapsed: false,
  };
}
