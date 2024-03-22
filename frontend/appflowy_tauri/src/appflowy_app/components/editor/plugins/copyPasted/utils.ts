import { ReactEditor } from 'slate-react';
import { Editor, Node, Location, Range, Path, Element, Text, Transforms, NodeEntry } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { LIST_TYPES } from '$app/components/editor/command/tab';

/**
 * Rewrite the insertFragment function to avoid the empty node(doesn't have text node) in the fragment

 * @param editor
 * @param fragment
 * @param options
 */
export function insertFragment(
  editor: ReactEditor,
  fragment: (Text | Element)[],
  options: {
    at?: Location;
    hanging?: boolean;
    voids?: boolean;
  } = {}
) {
  Editor.withoutNormalizing(editor, () => {
    const { hanging = false, voids = false } = options;
    let { at = getDefaultInsertLocation(editor) } = options;

    if (!fragment.length) {
      return;
    }

    if (Range.isRange(at)) {
      if (!hanging) {
        at = Editor.unhangRange(editor, at, { voids });
      }

      if (Range.isCollapsed(at)) {
        at = at.anchor;
      } else {
        const [, end] = Range.edges(at);

        if (!voids && Editor.void(editor, { at: end })) {
          return;
        }

        const pointRef = Editor.pointRef(editor, end);

        Transforms.delete(editor, { at });
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        at = pointRef.unref()!;
      }
    } else if (Path.isPath(at)) {
      at = Editor.start(editor, at);
    }

    if (!voids && Editor.void(editor, { at })) {
      return;
    }

    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const blockMatch = Editor.above(editor, {
      match: (n) => Element.isElement(n) && Editor.isBlock(editor, n) && n.blockId !== undefined,
      at,
      voids,
    })!;
    const [block, blockPath] = blockMatch as NodeEntry<Element>;

    const isEmbedBlock = Element.isElement(block) && editor.isEmbed(block);
    const isPageBlock = Element.isElement(block) && block.type === EditorNodeType.Page;
    const isBlockStart = Editor.isStart(editor, at, blockPath);
    const isBlockEnd = Editor.isEnd(editor, at, blockPath);
    const isBlockEmpty = isBlockStart && isBlockEnd;

    if (isEmbedBlock) {
      insertOnEmbedBlock(editor, fragment, blockPath);
      return;
    }

    if (isBlockEmpty && !isPageBlock) {
      const node = fragment[0] as Element;

      if (block.type !== EditorNodeType.Paragraph) {
        node.type = block.type;
        node.data = {
          ...(node.data || {}),
          ...(block.data || {}),
        };
      }

      insertOnEmptyBlock(editor, fragment, blockPath);
      return;
    }

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const fragmentRoot: Node = {
      children: fragment,
    };
    const [, firstPath] = Node.first(fragmentRoot, []);
    const [, lastPath] = Node.last(fragmentRoot, []);
    const sameBlock = Path.equals(firstPath.slice(0, -1), lastPath.slice(0, -1));

    if (sameBlock) {
      insertTexts(
        editor,
        isPageBlock
          ? ({
              children: [
                {
                  text: CustomEditor.getNodeTextContent(fragmentRoot),
                },
              ],
            } as Node)
          : fragmentRoot,
        at
      );
      return;
    }

    const isListTypeBlock = LIST_TYPES.includes(block.type as EditorNodeType);
    const [, ...blockChildren] = block.children;

    const blockEnd = editor.end([...blockPath, 0]);
    const afterRange: Range = { anchor: at, focus: blockEnd };

    const afterTexts = getTexts(editor, {
      children: editor.fragment(afterRange),
    } as Node) as (Text | Element)[];

    Transforms.delete(editor, { at: afterRange });

    const { startTexts, startChildren, middles } = getFragmentGroup(editor, fragment);

    insertNodes(
      editor,
      isPageBlock
        ? [
            {
              text: CustomEditor.getNodeTextContent({
                children: startTexts,
              } as Node),
            },
          ]
        : startTexts,
      {
        at,
      }
    );

    if (isPageBlock) {
      insertNodes(editor, [...startChildren, ...middles], {
        at: Path.next(blockPath),
        select: true,
      });
    } else {
      if (blockChildren.length > 0) {
        const path = [...blockPath, 1];

        insertNodes(editor, [...startChildren, ...middles], {
          at: path,
          select: true,
        });
      } else {
        const newMiddle = [...middles];

        if (isListTypeBlock) {
          const path = [...blockPath, 1];

          insertNodes(editor, startChildren, {
            at: path,
            select: newMiddle.length === 0,
          });
        } else {
          newMiddle.unshift(...startChildren);
        }

        insertNodes(editor, newMiddle, {
          at: Path.next(blockPath),
          select: true,
        });
      }
    }

    const { selection } = editor;

    if (!selection) return;

    insertNodes(editor, afterTexts, {
      at: selection,
    });
  });
}

function getFragmentGroup(editor: ReactEditor, fragment: Node[]) {
  const startTexts = [];
  const startChildren = [];
  const middles = [];

  const [firstNode, ...otherNodes] = fragment;
  const [firstNodeText, ...firstNodeChildren] = (firstNode as Element).children as Element[];

  startTexts.push(...firstNodeText.children);
  startChildren.push(...firstNodeChildren);

  for (const node of otherNodes) {
    if (Element.isElement(node) && node.blockId !== undefined) {
      middles.push(node);
    }
  }

  return {
    startTexts,
    startChildren,
    middles,
  };
}

function getTexts(editor: ReactEditor, fragment: Node) {
  const matches = [];
  const matcher = ([n]: NodeEntry) => Text.isText(n) || (Element.isElement(n) && editor.isInline(n));

  for (const entry of Node.nodes(fragment, { pass: matcher })) {
    if (matcher(entry)) {
      matches.push(entry[0]);
    }
  }

  return matches;
}

function insertTexts(editor: ReactEditor, fragmentRoot: Node, at: Location) {
  const matches = getTexts(editor, fragmentRoot);

  insertNodes(editor, matches, {
    at,
    select: true,
  });
}

function insertOnEmptyBlock(editor: ReactEditor, fragment: Node[], blockPath: Path) {
  editor.removeNodes({
    at: blockPath,
  });

  insertNodes(editor, fragment, {
    at: blockPath,
    select: true,
  });
}

function insertOnEmbedBlock(editor: ReactEditor, fragment: Node[], blockPath: Path) {
  insertNodes(editor, fragment, {
    at: Path.next(blockPath),
    select: true,
  });
}

function insertNodes(editor: ReactEditor, nodes: Node[], options: { at?: Location; select?: boolean } = {}) {
  try {
    Transforms.insertNodes(editor, nodes, options);
  } catch (e) {
    try {
      editor.move({
        distance: 1,
        unit: 'line',
      });
    } catch (e) {
      // do nothing
    }
  }
}

/**
 * Copy Code from slate/src/utils/get-default-insert-location.ts
 * Get the default location to insert content into the editor.
 * By default, use the selection as the target location. But if there is
 * no selection, insert at the end of the document since that is such a
 * common use case when inserting from a non-selected state.
 */
export const getDefaultInsertLocation = (editor: Editor): Location => {
  if (editor.selection) {
    return editor.selection;
  } else if (editor.children.length > 0) {
    return Editor.end(editor, []);
  } else {
    return [0];
  }
};

export function transFragment(editor: ReactEditor, fragment: Node[]) {
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
