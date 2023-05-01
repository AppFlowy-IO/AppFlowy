import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { getBeforeRangeAt } from '$app/utils/document/slate/text';
import { Editor } from 'slate';

export function canHandleToHeadingBlock(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor): boolean {
  const isSpaceKey = event.key === keyBoardEventKeyMap.Space;
  const selection = editor.selection;

  if (!isSpaceKey || !selection) {
    return false;
  }

  const beforeSpaceContent = Editor.string(editor, getBeforeRangeAt(editor, selection));

  const isHeadingMarkdown = /^(#{1,3})$/.test(beforeSpaceContent.trim());

  return isHeadingMarkdown;
}
