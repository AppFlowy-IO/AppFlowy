import { useContext, useEffect, useState } from "react";
import { BlockContext, getDocumentBlocksMap } from "$app/utils/block_context";
import { buildTree } from "$app/utils/tree";
import { Block } from "$app/interfaces";

export function useBlockList() {
  const blockContext = useContext(BlockContext);
  
  const [blockList, setBlockList] = useState<Block[]>([]);

  const [title, setTitle] = useState<string>('');

  useEffect(() => {

    if (!blockContext) return;

    const { id } = blockContext;
    if (!id) return;

    const blocksMap = getDocumentBlocksMap(id);
    if (!blocksMap) return;

    const root = buildTree(id, blocksMap);
    if (!root) return;
    console.log(root);
    setTitle(root.data.title);
    setBlockList(root.children || []);
  }, [blockContext]);

  return {
    title,
    blockList
  }
}
