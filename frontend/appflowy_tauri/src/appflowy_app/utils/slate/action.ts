import { BlockEditor } from "@/appflowy_app/block_editor";
import { TreeNode } from "@/appflowy_app/block_editor/tree_node";
import { Editor } from "slate";

export function triggerEnter(blockEditor: BlockEditor, editor: Editor, node: TreeNode) {
  const foucs = editor.selection?.focus;
  if (!foucs) return;
  
  const parentIndex = foucs.path[0];
  const index = foucs.path[1];
  const editorNode = editor.children[parentIndex];
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  const children: { [key: string]: boolean | string }[] = editorNode.children;
  const retainItems = children.filter((_: any, i: number) => i < index);
  const splitItem: { [key: string]: boolean | string } = children[index];
  const text = splitItem.text.toString();
  const prevText = text.substring(0, foucs.offset);
  const afterText = text.substring(foucs.offset);
  retainItems.push({
    ...splitItem,
    text: prevText
  });

  const removeItems = children.filter((_: any, i: number) => i > index);

  const data = {
    type: node.type,
    data: {
      ...node.data,
      content: [
        {
          ...splitItem,
          text: afterText
        },
        ...removeItems
      ]
    }
  };

  blockEditor.sync.update(node.id, {
    paths: ['data', 'content'],
    data: retainItems
  });
  const newBlock = blockEditor.sync.addSibling(node.id, data);
  if (!newBlock) return;

  const len = node.children.length;
  if (len > 0) {
    blockEditor.sync.moveBulk(node.children[0].id, node.children[len - 1].id, newBlock.id, '')
  }

  blockEditor.sync.sendOps();
  return newBlock;
}