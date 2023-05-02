import { Editor } from 'slate';
import { getAfterRangeAt, getBeforeRangeAt } from '$app/utils/document/slate/text';
import { BlockType, HeadingBlockData, NestedBlock } from '$app/interfaces/document';
import { getDeltaFromSlateNodes, newBlock } from '$app/utils/document/blocks/common';

export function newHeadingBlock(parentId: string, data: HeadingBlockData): NestedBlock {
  return newBlock<BlockType.HeadingBlock>(BlockType.HeadingBlock, parentId, data);
}

export function getHeadingDataFromEditor(editor: Editor): HeadingBlockData | undefined {
  const selection = editor.selection;
  if (!selection) return;
  const hashTags = Editor.string(editor, getBeforeRangeAt(editor, selection));
  const level = hashTags.match(/#/g)?.length;
  if (!level) return;
  const slateNodes = Editor.fragment(editor, getAfterRangeAt(editor, selection));
  const delta = getDeltaFromSlateNodes(slateNodes);
  return {
    level,
    delta,
  };
}
