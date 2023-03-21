interface NodeInfo {
  id: string;
  parent: NodeInfo | null;
  children: NodeInfo[];
}

type NodeMap = Map<string, NodeInfo>;
export function filterSelections(ids: string[], nodeMap: NodeMap): string[] {
  const selected = new Set(ids);
  const newSelected = new Set<string>();
  ids.forEach(selectedId => {
    if (nodeMap.get(selectedId)?.children.length === 0) {
      newSelected.add(selectedId);
      return;
    }
    const hasChildSelected = nodeMap.get(selectedId)?.children.some(i => selected.has(i.id));
    if (!hasChildSelected) {
      newSelected.add(selectedId);
      return;
    }
    const hasSiblingSelected = nodeMap.get(selectedId)?.parent?.children.filter(i => i.id !== selectedId).some(i => selected.has(i.id));
    if (hasChildSelected && hasSiblingSelected) {
      newSelected.add(selectedId);
      return;
    }
  });

  return Array.from(newSelected);
}
