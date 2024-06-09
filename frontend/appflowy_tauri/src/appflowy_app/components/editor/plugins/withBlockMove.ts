import { ReactEditor } from 'slate-react';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { Editor, Element, Location, NodeEntry, Path, Node, Transforms } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';

const matchPath = (editor: Editor, path: Path): ((node: Node) => boolean) => {
  const [node] = Editor.node(editor, path);

  return (n) => {
    return n === node;
  };
};

export function withBlockMove(editor: ReactEditor) {
  const { moveNodes } = editor;

  editor.moveNodes = (args) => {
    const { to } = args;

    moveNodes(args);

    replaceId(editor, to);
  };

  editor.liftNodes = (args = {}) => {
    Editor.withoutNormalizing(editor, () => {
      const { at = editor.selection, mode = 'lowest', voids = false } = args;
      let { match } = args;

      if (!match) {
        match = Path.isPath(at)
          ? matchPath(editor, at)
          : (n) => Element.isElement(n) && Editor.isBlock(editor, n) && n.blockId !== undefined;
      }

      if (!at) {
        return;
      }

      const matches = Editor.nodes(editor, { at, match, mode, voids });

      const pathRefs = Array.from(matches, ([, p]) => {
        return Editor.pathRef(editor, p);
      });

      for (const pathRef of pathRefs) {
        const path = pathRef.unref();

        if (!path) return;
        if (path.length < 2) {
          throw new Error(`Cannot lift node at a path [${path}] because it has a depth of less than \`2\`.`);
        }

        const parentNodeEntry = Editor.node(editor, Path.parent(path));
        const [parent, parentPath] = parentNodeEntry as NodeEntry<Element>;
        const index = path[path.length - 1];
        const { length } = parent.children;

        if (length === 1) {
          const toPath = Path.next(parentPath);

          Transforms.moveNodes(editor, { at: path, to: toPath, voids });
          Transforms.removeNodes(editor, { at: parentPath, voids });
        } else if (index === 0) {
          Transforms.moveNodes(editor, { at: path, to: parentPath, voids });
        } else if (index === length - 1) {
          const toPath = Path.next(parentPath);

          Transforms.moveNodes(editor, { at: path, to: toPath, voids });
        } else {
          const toPath = Path.next(parentPath);

          const node = parent.children[index] as Element;
          const nodeChildrenLength = node.children.length;

          for (let i = length - 1; i > index; i--) {
            Transforms.moveNodes(editor, {
              at: [...parentPath, i],
              to: [...path, nodeChildrenLength],
              mode: 'all',
            });
          }

          Transforms.moveNodes(editor, { at: path, to: toPath, voids });
        }
      }
    });
  };

  return editor;
}

function replaceId(editor: Editor, at?: Location) {
  const newBlockId = generateId();
  const newTextId = generateId();

  const selection = editor.selection;

  const location = at || selection;

  if (!location) return;

  const [node, path] = editor.node(location) as NodeEntry<Element>;

  if (node.blockId === undefined) {
    return;
  }

  const [textNode, ...children] = node.children as Element[];

  editor.setNodes(
    {
      blockId: newBlockId,
    },
    {
      at,
    }
  );

  if (textNode && textNode.type === EditorNodeType.Text) {
    editor.setNodes(
      {
        textId: newTextId,
      },
      {
        at: [...path, 0],
      }
    );
  }

  children.forEach((_, index) => {
    replaceId(editor, [...path, index + 1]);
  });
}
