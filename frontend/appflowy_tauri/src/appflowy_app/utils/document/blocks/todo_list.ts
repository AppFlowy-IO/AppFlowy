import { Editor } from 'slate';
import { TodoListBlockData } from '$app/interfaces/document';
import { getAfterRangeAt, getBeforeRangeAt } from '$app/utils/document/slate/text';
import { getDeltaFromSlateNodes } from '$app/utils/document/blocks/common';

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
