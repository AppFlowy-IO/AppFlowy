import { Block } from '../interfaces/index';
import { DOMTree } from './dom_tree';

export class BlockManager {

  blocksMap: Record<string, Block> | null = null;

  private tree: DOMTree;

  constructor(private id: string, data: Record<string, Block>) {
    this.blocksMap = data;
    this.tree = new DOMTree(this.getBlock);
  }

  /**
   * create render Tree
   * @returns rootNode
   */
  createDOMTree = () => {
    this.tree.build(this.id);
    return this.tree.root;
  }

  /**
   * update dom rects cache
   */
  updateDOMTreeRects = () => {
    this.tree.rect.build();
  }

  /**
   * get block data
   * @param id string
   * @returns Block
   */
  getBlock = (id: string) => {
    return this.blocksMap?.[id] || null;
  }

  /**
   * get block rect cache
   * @param id string
   * @returns DOMRect
   */
  getBlockRect = (id: string) => {
    return this.tree.rect.getBlockRect(id);
  }

  /**
   * update block rect cache
   * @param id string
   */
  updateBlockRect = (id: string) => {
    this.tree.rect.updateBlockRect(id);
  }

  /**
   * update id and map when the doc is change
   * @param id 
   * @param data 
   */
  changeDoc = (id: string, data: Record<string, Block>) => {
    console.log('==== change document ====', id, data)
    this.id = id;
    this.blocksMap = data;
  }

  destroy = () => {
    this.tree.destroy();
    this.blocksMap = null;
  }
  
}

let blockManagerInstance: BlockManager | null;

export function getBlockManagerInstance() {
  return blockManagerInstance;
}

export function createBlockManagerInstance(id: string, data: Record<string, Block>) {
  blockManagerInstance = new BlockManager(id, data);
  return blockManagerInstance;
}