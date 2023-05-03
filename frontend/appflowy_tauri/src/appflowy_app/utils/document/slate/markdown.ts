import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { getBeforeRangeAt } from '$app/utils/document/slate/text';
import { Editor } from 'slate';

export function canHandleToHeadingBlock(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor): boolean {
  const flag = getMarkdownFlag(event, editor);
  if (!flag) return false;
  const isHeadingMarkdown = /^(#{1,3})$/.test(flag);

  return isHeadingMarkdown;
}

export function canHandleToCheckboxBlock(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const flag = getMarkdownFlag(event, editor);
  if (!flag) return false;

  const isCheckboxMarkdown = /^((-)?\[(x|\s)?\])$/.test(flag);
  return isCheckboxMarkdown;
}

export function canHandleToQuoteBlock(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const flag = getMarkdownFlag(event, editor);
  if (!flag) return false;

  const isQuoteMarkdown = /^("|“|”)$/.test(flag);

  return isQuoteMarkdown;
}

function getMarkdownFlag(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  const isSpaceKey = event.key === keyBoardEventKeyMap.Space;
  const selection = editor.selection;

  if (!isSpaceKey || !selection) {
    return null;
  }

  return Editor.string(editor, getBeforeRangeAt(editor, selection)).trim();
}
