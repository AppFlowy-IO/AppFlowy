import { CONTAINER_BLOCK_TYPES, SOFT_BREAK_TYPES } from '@/application/slate-yjs/command/const';
import { BlockType } from '@/application/types';
import { withDelete } from '@/components/editor/plugins/withDelete';
import { withInsertBreak } from '@/components/editor/plugins/withInsertBreak';
import { withInsertText } from '@/components/editor/plugins/withInsertText';
import { withMarkdown } from '@/components/editor/plugins/withMarkdown';
import { withPasted } from '@/components/editor/plugins/withPasted';
import { ReactEditor } from 'slate-react';
import { withCopy } from '@/components/editor/plugins/withCopy';
import { withInsertData } from '@/components/editor/plugins/withInsertData';

export function withPlugins(editor: ReactEditor) {
  const {
    isElementReadOnly,
  } = editor;

  editor.isElementReadOnly = (element) => {

    if (element.blockId && ![
      ...CONTAINER_BLOCK_TYPES,
      ...SOFT_BREAK_TYPES,
      BlockType.HeadingBlock,
    ].includes(element.type as BlockType)) {
      return true;
    }

    return isElementReadOnly(element);
  };

  return withInsertData(withPasted(withCopy(withMarkdown(withInsertBreak(withDelete(withInsertText(editor)))))));
}
