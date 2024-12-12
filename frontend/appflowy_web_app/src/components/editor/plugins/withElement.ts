import { ReactEditor } from 'slate-react';
import { isEmbedBlockTypes } from '@/application/slate-yjs/command/const';
import { BlockType } from '@/application/types';
import { Element, NodeEntry } from 'slate';

export const withElement = (editor: ReactEditor) => {
  const {
    isElementReadOnly,
    isEmbed,
  } = editor;

  editor.isEmbed = (element) => {
    if (isEmbedBlockTypes(element.type as BlockType)) {
      return true;
    }

    return isEmbed(element);
  };

  editor.isElementReadOnly = (element) => {

    try {
      const path = ReactEditor.findPath(editor, element);
      const parent = editor.parent(path, {
        depth: 2,
      }) as NodeEntry<Element>;

      const readOnlyTypes = [BlockType.SimpleTableBlock, BlockType.TableBlock];

      if (readOnlyTypes.includes(parent[0].type as BlockType)) {
        return true;
      }

    } catch (e) {
      //
    }

    return isElementReadOnly(element);
  };

  return editor;
};