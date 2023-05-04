import { Editor } from 'slate';
import { HeadingBlockData, TodoListBlockData } from '$app/interfaces/document';
import { getAfterRangeAt, getBeforeRangeAt } from '$app/utils/document/slate/text';
import { getDeltaAfterSelection, getDeltaFromSlateNodes } from '$app/utils/document/blocks/common';

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
  const slateNodes = Editor.fragment(editor, getAfterRangeAt(editor, selection));
  const delta = getDeltaFromSlateNodes(slateNodes);
  return {
    delta,
    checked: !!checked,
  };
}
