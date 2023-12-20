import { ReactEditor } from 'slate-react';
import { Editor, Element } from 'slate';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { blockTypes, EditorNodeType } from '$app/application/document/document.types';

export function withPasted(editor: ReactEditor) {
  const { insertFragment } = editor;

  editor.insertFragment = (fragment) => {
    let rootId = (editor.children[0] as Element)?.blockId;

    if (!rootId) {
      rootId = generateId();
      insertFragment([
        {
          type: EditorNodeType.Paragraph,
          children: [
            {
              text: '',
            },
          ],
          data: {},
          blockId: rootId,
          textId: generateId(),
          parentId: '',
          level: 0,
        },
      ]);
    }

    const [mergedMatch] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type !== undefined,
    });

    const mergedNode = mergedMatch
      ? (mergedMatch[0] as Element & {
          blockId: string;
          parentId: string;
          level: number;
        })
      : null;

    if (!mergedNode) return insertFragment(fragment);

    const isEmpty = Editor.isEmpty(editor, mergedNode);

    const mergedNodeId = isEmpty ? undefined : mergedNode.blockId;

    const idMap = new Map<string, string>();
    const levelMap = new Map<string, number>();

    for (let i = 0; i < fragment.length; i++) {
      const node = fragment[i] as Element & {
        blockId: string;
        parentId: string;
        level: number;
      };

      const newBlockId = i === 0 && mergedNodeId ? mergedNodeId : generateId();

      const parentId = idMap.get(node.parentId);

      if (parentId) {
        node.parentId = parentId;
      } else {
        idMap.set(node.parentId, mergedNode.parentId);
        node.parentId = mergedNode.parentId;
      }

      const parentLevel = levelMap.get(node.parentId);

      if (parentLevel !== undefined) {
        node.level = parentLevel + 1;
      } else {
        levelMap.set(node.parentId, mergedNode.level - 1);
        node.level = mergedNode.level;
      }

      // if the pasted fragment is not matched with the block type, we need to convert it to paragraph
      // and if the pasted fragment is a page, we need to convert it to paragraph
      if (!blockTypes.includes(node.type as EditorNodeType) || node.type === EditorNodeType.Page) {
        node.type = EditorNodeType.Paragraph;
      }

      idMap.set(node.blockId, newBlockId);
      levelMap.set(newBlockId, node.level);
      node.blockId = newBlockId;
      node.textId = generateId();
    }

    return insertFragment(fragment);
  };

  return editor;
}
