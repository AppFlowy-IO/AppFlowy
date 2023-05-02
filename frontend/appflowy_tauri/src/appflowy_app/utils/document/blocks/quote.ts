import { Editor } from 'slate';
import { getDeltaAfterSelection } from '$app/utils/document/blocks/common';

export function getQuoteDataFromEditor(editor: Editor) {
  const delta = getDeltaAfterSelection(editor);
  if (!delta) return;
  return {
    delta,
    size: 'default',
  };
}
