import { BaseEditor, BaseSelection, Descendant, Editor, Transforms } from "slate";
import { TreeNode } from '$app/block_editor/view/tree_node';
import { Operation } from "$app/block_editor/core/operation";
import { TextBlockSelectionManager } from './text_selection';
import { BlockType } from "@/appflowy_app/interfaces";
import { ReactEditor } from "slate-react";

export class TextBlockManager {
  public selectionManager: TextBlockSelectionManager;
  private editorMap: Map<string, BaseEditor & ReactEditor> = new Map();

  constructor(private rootId: string, private operation: Operation) {
    this.selectionManager = new TextBlockSelectionManager();
  }

  register(id: string, editor: BaseEditor & ReactEditor) {
    this.editorMap.set(id, editor);
  }

  unregister(id: string) {
    this.editorMap.delete(id);
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
      this.operation.updateNode(node.id, ['data'], { content: node.data.content });
      return;
    }

    if (!node.block.next && node.parent!.id !== this.rootId) {
      const newParent = node.parent!.parent!;
      const newPrev = node.parent;
      this.operation.moveNode(node.id, newParent.id, newPrev?.id || '');
      return;
    }
    if (!node.prevLine) return;

    const retainData = node.prevLine.data.content;
    const editor = this.editorMap.get(node.prevLine.id);
    if (editor) {
      const index = retainData.length - 1;
      const anchor = {
        path: [0, index],
        offset: retainData[index].text.length,
      };
      const selection = {
        anchor,
        focus: {...anchor}
      };
      ReactEditor.focus(editor);
      Transforms.select(editor, selection);
    }

    this.operation.updateNode(node.prevLine.id, ['data', 'content'], [
      ...retainData,
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