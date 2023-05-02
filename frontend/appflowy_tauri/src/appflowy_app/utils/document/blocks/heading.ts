import { Editor } from 'slate';
import { getAfterRangeAt, getBeforeRangeAt } from '$app/utils/document/slate/text';
import { HeadingBlockData } from '$app/interfaces/document';
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
