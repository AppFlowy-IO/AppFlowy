import { BaseEditor, BaseSelection, Descendant } from "slate";
import { TreeNode } from '$app/block_editor/view/tree_node';
import { Operation } from "$app/block_editor/core/operation";
import { TextBlockSelectionManager } from './text_selection';
import { BlockType } from "@/appflowy_app/interfaces";

export class TextBlockManager {
  public selectionManager: TextBlockSelectionManager;
  constructor(private rootId: string, private operation: Operation) {
    this.selectionManager = new TextBlockSelectionManager();
  }

  setSelection(node: TreeNode, selection: BaseSelection) {
    // console.log(node.id, selection);
    this.selectionManager.setSelection(node.id, selection)
  }

  update(node: TreeNode, path: string[], data: Descendant[]) {
    this.operation.updateNode(node.id, path, data);
  }

  deleteNode(node: TreeNode) {
    if (node.type !== BlockType.TextBlock) {
      this.operation.updateNode(node.id, ['type'], BlockType.TextBlock);
      return;
    }
    if (node.parent!.id !== this.rootId) {
      const newParent = node.parent!.parent!;
      const newPrev = node.parent;
      this.operation.moveNode(node.id, newParent.id, newPrev?.id || '');
    }
    if (!node.prevLine) return;
    this.operation.updateNode(node.prevLine.id, ['data', 'content'], [
      ...node.prevLine.data.content,
      ...node.data.content,
    ]);
    this.operation.deleteNode(node.id);
  }

  splitNode(node: TreeNode, editor: BaseEditor) {
    const focus = editor.selection?.focus;
    const path = focus?.path || [0, editor.children.length - 1];
    const offset = focus?.offset || 0;
    const parentIndex = path[0];
    const index = path[1];
    const editorNode = editor.children[parentIndex];
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const children: { [key: string]: boolean | string; text: string }[] = editorNode.children;
    const retainItems = children.filter((_: any, i: number) => i < index);
    const splitItem: { [key: string]: boolean | string } = children[index];
    const text = splitItem.text.toString();
    const prevText = text.substring(0, offset);
    const afterText = text.substring(offset);
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

    const newBlock = this.operation.splitNode(node.id, {
      path: ['data', 'content'],
      value: retainItems,
    }, data);
    newBlock && this.selectionManager.focusStart(newBlock.id);
  }

  destroy() {
    this.selectionManager.destroy();
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.operation = null;
  }

}