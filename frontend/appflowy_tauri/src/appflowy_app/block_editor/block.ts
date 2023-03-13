import { BlockInterface, BlockType } from '$app/interfaces/index';


export class BlockDataManager {
  private head: BlockInterface<BlockType.PageBlock> | null = null;
  constructor(id: string, private map: Record<string, BlockInterface<BlockType>> | null) {
    if (!map) return;
    this.head = map[id];
  }

  setBlocksMap = (id: string, map: Record<string, BlockInterface<BlockType>>) => {
    this.map = map;
    this.head = map[id];
  }

  /**
   * get block data
   * @param blockId string
   * @returns Block
   */
  getBlock = (blockId: string) => {
    return this.map?.[blockId] || null;
  }

  destroy() {
    this.map = null;
  }
}