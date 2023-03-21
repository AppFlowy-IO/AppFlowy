import { BlockData, BlockType } from "../interfaces";


export function filterSelections<TreeNode extends {
  id: string;
  children: TreeNode[];
  parent: TreeNode | null;
  type: BlockType;
  data: BlockData;
}>(ids: string[], nodeMap: Map<string, TreeNode>): string[] {
  const selected = new Set(ids);
  const newSelected = new Set<string>();
  ids.forEach(selectedId => {
    const node = nodeMap.get(selectedId);
    if (!node) return;
    if (node.type === BlockType.ListBlock && node.data.type === 'column') {
      return;
    }
    if (node.children.length === 0) {
      newSelected.add(selectedId);
      return;
    }
    const hasChildSelected = node.children.some(i => selected.has(i.id));
    if (!hasChildSelected) {
      newSelected.add(selectedId);
      return;
    }
    const hasSiblingSelected = node.parent?.children.filter(i => i.id !== selectedId).some(i => selected.has(i.id));
    if (hasChildSelected && hasSiblingSelected) {
      newSelected.add(selectedId);
      return;
    }
  });

  return Array.from(newSelected);
}
