import { BlockInterface } from '../interfaces';
import { BlockDataManager } from './block';
import { TreeManager } from './tree';

/**
 * BlockEditor is a document data manager that operates on and renders data through managing blockData and RenderTreeManager.
 * The render tree will be re-render and update react component when block makes changes to the data.
 * RectManager updates the cache of node rect when the react component update is completed.
 */
export class BlockEditor {
  // blockData manages document block data, including operations such as add, delete, update, and move.
  public blockData: BlockDataManager;
  // RenderTreeManager manages data rendering, including the construction and updating of the render tree.
  public renderTree: TreeManager;

  constructor(private id: string, data: Record<string, BlockInterface>) {
    this.blockData = new BlockDataManager(id, data);
    this.renderTree = new TreeManager(this.blockData.getBlock);
  }

  /**
   * update id and map when the doc is change
   * @param id 
   * @param data 
   */
  changeDoc = (id: string, data: Record<string, BlockInterface>) => {
    console.log('==== change document ====', id, data)
    this.id = id;
    this.blockData.setBlocksMap(id, data);
  }

  destroy = () => {
    this.renderTree.destroy();
    this.blockData.destroy();
  }
  
}

let blockEditorInstance: BlockEditor | null;

export function getBlockEditor() {
  return blockEditorInstance;
}

export function createBlockEditor(id: string, data: Record<string, BlockInterface>) {
  blockEditorInstance = new BlockEditor(id, data);
  return blockEditorInstance;
}