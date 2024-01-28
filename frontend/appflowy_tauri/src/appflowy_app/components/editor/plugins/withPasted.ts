import { ReactEditor } from 'slate-react';
import { convertBlockToJson } from '$app/application/document/document.service';
import { Editor, Element, NodeEntry, Path, Node, Text, Location, Range } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { InputType } from '@/services/backend';
import { CustomEditor } from '$app/components/editor/command';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { LIST_TYPES } from '$app/components/editor/command/tab';
import { Log } from '$app/utils/log';

export function withPasted(editor: ReactEditor) {
  const { insertData, insertFragment, setFragmentData } = editor;

  editor.setFragmentData = (...args) => {
    if (!editor.selection) {
      setFragmentData(...args);
      return;
    }

    // selection is collapsed and the node is an embed, we need to set the data manually
    if (Range.isCollapsed(editor.selection)) {
      const match = Editor.above(editor, {
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
      });
      const node = match ? (match[0] as Element) : undefined;

      if (node && editor.isEmbed(node)) {
        const fragment = editor.getFragment();

        if (fragment.length > 0) {
          const data = args[0];
          const string = JSON.stringify(fragment);
          const encoded = window.btoa(encodeURIComponent(string));

          const dom = ReactEditor.toDOMNode(editor, node);

          data.setData(`application/x-slate-fragment`, encoded);
          data.setData(`text/html`, dom.innerHTML);
        }
      }
    }

    setFragmentData(...args);
  };

  editor.insertData = (data) => {
    const fragment = data.getData('application/x-slate-fragment');

    if (fragment) {
      insertData(data);
      return;
    }

    const html = data.getData('text/html');
    const text = data.getData('text/plain');

    if (!html && !text) {
      insertData(data);
      return;
    }

    void (async () => {
      try {
        const nodes = await convertBlockToJson(html, InputType.Html);

        const htmlTransNoText = nodes.every((node) => {
          return CustomEditor.getNodeTextContent(node).length === 0;
        });

        if (!htmlTransNoText) {
          return editor.insertFragment(nodes);
        }
      } catch (e) {
        Log.warn('pasted html error', e);
        // ignore
      }

      if (text) {
        const nodes = await convertBlockToJson(text, InputType.PlainText);

        editor.insertFragment(nodes);
        return;
      }
    })();
  };

  editor.insertFragment = (fragment, options = {}) => {
    Editor.withoutNormalizing(editor, () => {
      const { at = getDefaultInsertLocation(editor) } = options;

      if (!fragment.length) {
        return;
      }

      if (Range.isRange(at) && !Range.isCollapsed(at)) {
        editor.delete({
          unit: 'character',
        });
      }

      const selection = editor.selection;

      if (!selection) return;

      const [node] = editor.node(selection);
      const isText = Text.isText(node);
      const parent = Editor.above(editor, {
        at: selection,
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
      });

      if (isText && parent) {
        const [parentNode, parentPath] = parent as NodeEntry<Element>;
        const pastedNodeIsPage = parentNode.type === EditorNodeType.Page;
        const clonedFragment = transFragment(editor, fragment);

        const [firstNode, ...otherNodes] = clonedFragment;
        const lastNode = getLastNode(otherNodes[otherNodes.length - 1]);
        const firstIsEmbed = editor.isEmbed(firstNode);
        const insertNodes: Element[] = [...otherNodes];
        const needMoveChildren = parentNode.children.length > 1 && !pastedNodeIsPage;
        let moveStartIndex = 0;

        if (firstIsEmbed) {
          insertNodes.unshift(firstNode);
        } else {
          // merge the first fragment node with the current text node
          const [textNode, ...children] = firstNode.children as Element[];

          const textElements = textNode.children;

          const end = Editor.end(editor, [...parentPath, 0]);

          // merge text node
          editor.insertNodes(textElements, {
            at: end,
            select: true,
          });

          if (children.length > 0) {
            if (pastedNodeIsPage) {
              // lift the children of the first fragment node to current node
              insertNodes.unshift(...children);
            } else {
              const lastChild = getLastNode(children[children.length - 1]);

              const lastIsEmbed = lastChild && editor.isEmbed(lastChild);

              // insert the children of the first fragment node to current node
              editor.insertNodes(children, {
                at: [...parentPath, 1],
                select: !lastIsEmbed,
              });

              moveStartIndex += children.length;
            }
          }
        }

        if (insertNodes.length === 0) return;

        // insert a new paragraph if the last node is an embed
        if ((!lastNode && firstIsEmbed) || (lastNode && editor.isEmbed(lastNode))) {
          insertNodes.push(generateNewParagraph());
        }

        const pastedPath = Path.next(parentPath);

        // insert the sibling of the current node
        editor.insertNodes(insertNodes, {
          at: pastedPath,
          select: true,
        });

        if (!needMoveChildren) return;

        if (!editor.selection) return;

        // current node is the last node of the pasted fragment
        const currentPath = editor.selection.anchor.path;
        const current = editor.above({
          at: currentPath,
          match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
        });

        if (!current) return;

        const [currentNode, currentNodePath] = current as NodeEntry<Element>;

        // split the operation into the next tick to avoid the wrong path
        if (LIST_TYPES.includes(currentNode.type as EditorNodeType)) {
          const length = currentNode.children.length;

          setTimeout(() => {
            // move the children of the current node to the last node of the pasted fragment
            for (let i = parentNode.children.length - 1; i > 0; i--) {
              editor.moveNodes({
                at: [...parentPath, i + moveStartIndex],
                to: [...currentNodePath, length],
              });
            }
          }, 0);
        } else {
          // if the current node is not a list, we need to move these children to the next path
          setTimeout(() => {
            const nextPath = Path.next(currentNodePath);

            for (let i = parentNode.children.length - 1; i > 0; i--) {
              editor.moveNodes({
                at: [...parentPath, i + moveStartIndex],
                to: nextPath,
              });
            }
          }, 0);
        }
      } else {
        insertFragment(fragment);
        return;
      }
    });
  };

  return editor;
}

export const getDefaultInsertLocation = (editor: Editor): Location => {
  if (editor.selection) {
    return editor.selection;
  } else if (editor.children.length > 0) {
    return Editor.end(editor, []);
  } else {
    return [0];
  }
};

export const generateNewParagraph = (): Element => ({
  type: EditorNodeType.Paragraph,
  blockId: generateId(),
  children: [
    {
      type: EditorNodeType.Text,
      textId: generateId(),
      children: [{ text: '' }],
    },
  ],
});

function getLastNode(node: Node): Element | undefined {
  if (!Element.isElement(node) || node.blockId === undefined) return;

  if (Element.isElement(node) && node.blockId !== undefined && node.children.length > 0) {
    const child = getLastNode(node.children[node.children.length - 1]);

    if (!child) {
      return node;
    } else {
      return child;
    }
  }

  return node;
}

function transFragment(editor: ReactEditor, fragment: Node[]) {
  // flatten the fragment to avoid the empty node(doesn't have text node) in the fragment
  const flatMap = (node: Node): Node[] => {
    const isInputElement =
      !Editor.isEditor(node) && Element.isElement(node) && node.blockId !== undefined && !editor.isEmbed(node);

    if (
      isInputElement &&
      node.children?.length > 0 &&
      Element.isElement(node.children[0]) &&
      node.children[0].type !== EditorNodeType.Text
    ) {
      return node.children.flatMap((child) => flatMap(child));
    }

    return [node];
  };

  const fragmentFlatMap = fragment?.flatMap(flatMap);

  // clone the node to avoid the duplicated block id
  return fragmentFlatMap.map((item) => CustomEditor.cloneBlock(editor, item as Element));
}
