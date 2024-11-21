import { Editor, Element, NodeEntry, Path, Range, Transforms, Node, Point, BasePoint } from 'slate';
import { ReactEditor } from 'slate-react';

export function findIndentPath (originalStart: Path, originalEnd: Path, newStart: Path): Path {
  // Find the common ancestor path
  const commonPath = Path.common(originalStart, originalEnd);

  // Calculate end's path relative to common ancestor
  const endRelativePath = originalEnd.slice(commonPath.length);

  // Calculate new common ancestor path by maintaining the same level difference
  const startToCommonLevels = originalStart.length - commonPath.length;
  const newCommonAncestor = newStart.slice(0, newStart.length - startToCommonLevels);

  // Append the relative path to new common ancestor
  return [...newCommonAncestor, ...endRelativePath];
}

export function findLiftPath (originalStart: Path, originalEnd: Path, newStart: Path): Path {
  // Same logic as findIndentPath
  const commonPath = Path.common(originalStart, originalEnd);
  const endRelativePath = originalEnd.slice(commonPath.length);
  const startToCommonLevels = originalStart.length - commonPath.length;
  const newCommonAncestor = newStart.slice(0, newStart.length - startToCommonLevels);

  return [...newCommonAncestor, ...endRelativePath];
}

export function findSlateEntryByBlockId (editor: Editor, blockId: string) {
  const [node] = Editor.nodes(editor, {
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === blockId,
    at: [],
    mode: 'all',
    voids: true,
  });

  return node as NodeEntry<Element>;
}

export function beforePasted (editor: ReactEditor) {
  const { selection } = editor;

  if (!selection) {
    return false;
  }

  if (Range.isExpanded(selection)) {
    Transforms.collapse(editor, { edge: 'start' });

    editor.delete({
      at: selection,
    });
  }

  return true;
}

export function getSelectedPaths (editor: ReactEditor) {
  const { selection } = editor;

  if (!selection) {
    return null;
  }

  const [start, end] = Range.edges(selection);
  const startEntry = editor.above({
    at: start,
    match: n => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as unknown as NodeEntry<Element> | undefined;

  const endEntry = editor.above({
    at: end,
    match: n => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  }) as unknown as NodeEntry<Element> | undefined;

  const startBlockId = startEntry ? startEntry[0].blockId : undefined;
  const endBlockId = endEntry ? endEntry[0].blockId : undefined;

  const blockEntries = Array.from(
    Editor.nodes(editor, {
      at: selection,
      match: (n, path) => {
        // It's a block element if it's not the editor itself, it's an element, and it has a blockId
        const isBlockElement = !Editor.isEditor(n) &&
          Element.isElement(n) &&
          n.blockId !== undefined;

        if (!isBlockElement) return false;

        // Get the range of the block element
        const nodeRange = Editor.range(editor, path);
        const [anchor, focus] = editor.edges(nodeRange);

        if (n.blockId === startBlockId || n.blockId === endBlockId) {
          return true;
        }

        const isIntersecting = (anchor: BasePoint, focus: BasePoint) => {
          return Point.compare(anchor, start) >= 0 &&
            Point.compare(focus, end) <= 0;
        };

        // Check if the block element is fully within the selection
        if (isIntersecting(anchor, focus)) {
          return true;
        } else {
          // Check if the block element contains a text node that is within the selection
          const textNode = (n.children[0] as Element)?.textId !== undefined ? n.children[0] : null;

          if (textNode) {
            const [anchor, focus] = editor.edges([...path, 0]);

            return isIntersecting(anchor, focus);
          }
        }

        return false;
      },
      voids: true,
    }),
  );

  return blockEntries.map(([, path]) => path);
}

export function filterValidNodes (editor: ReactEditor, selectedPaths: Path[]): [
  Element,
  Path,
][] {
  const sortedPaths = selectedPaths.sort((a, b) =>
    Path.compare(a, b),
  );

  const validPaths = sortedPaths.filter((path, index) => {
    // Check if the current path is a child of any previous paths
    const isChildOfPrevious = sortedPaths
      .slice(0, index)
      .some(prevPath => Path.isDescendant(path, prevPath));

    return !isChildOfPrevious;
  });

  // Get the nodes from the valid paths
  return validPaths.map(path => {
    const node = Node.get(editor, path);

    return [node, path] as [Element, Path];
  });
}

export function isSameDepth (selectedPaths: Path[]) {
  const depth = selectedPaths[0].length;

  return selectedPaths.every(path => path.length === depth);
}

export function sortNodesByDepth (editor: Editor, selectedPaths: Path[]) {
  const pathsWithDepth = selectedPaths.map(path => ({
    path,
    depth: path.length,
    node: Node.get(editor, path),
  }));

  return pathsWithDepth.sort((a, b) => {
    // use depth to sort
    if (b.depth !== a.depth) {
      return b.depth - a.depth;
    }

    // if depth is same, use path comparison
    return Path.compare(a.path, b.path);
  });
}