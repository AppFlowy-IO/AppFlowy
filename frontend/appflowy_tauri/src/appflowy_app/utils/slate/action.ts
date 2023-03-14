import { BlockEditor } from "@/appflowy_app/block_editor";
import { TreeNode } from "@/appflowy_app/block_editor/tree_node";
import { BlockType } from "@/appflowy_app/interfaces";

export function triggerEnter(blockEditor: BlockEditor, node: TreeNode) {
  let newBlock;
  const data = {
    type: BlockType.TextBlock,
    data: {
      content: [{
        text: ''
      }]
    }
  };
  if (node.children.length === 0) {
    newBlock = blockEditor.sync.addSibling(node.id, data);
  } else {
    newBlock = blockEditor.sync.prependChild(node.id, data);
  }
  return newBlock;
}