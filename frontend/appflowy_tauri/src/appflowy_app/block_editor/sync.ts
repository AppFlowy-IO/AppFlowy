import { Block } from './block';
import { BlockChain } from './block_chain';
import { Operation, OPAdapter } from './op_adapter';
import { SelectionManager } from './selection';

/**
 * BlockEditorSync is a class that synchronizes changes made to a block chain with a server.
 * It allows for adding, removing, and moving blocks in the chain, and sends pending operations to the server.
 */
export class BlockEditorSync {
  private version = 0;
  private pendingOps: Operation[] = [];
  private appliedOps: Operation[] = [];
  private opAdapter: OPAdapter = new OPAdapter();
  
  constructor(private server: any, private blockChain: BlockChain, private selection: SelectionManager) {

  }

  public update(blockId: string, data: { paths: string[], data: any }) {
    const block = this.blockChain.updateBlock(blockId, data);
    const op = this.opAdapter.update(blockId, data);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
    return block;
  }

  public prependChild(parentId: string, content: any) {
    const newBlock = this.blockChain.prependChild(parentId, content);
    if (!newBlock) return;
    this.newBlockMovePos(newBlock);
    return newBlock;
  }

  public addSibling(prevId: string, content: any) {
    const newBlock = this.blockChain.addSibling(prevId, content);
    if (!newBlock) return;
    this.newBlockMovePos(newBlock);
    return newBlock;
  }

  public remove(blockId: string): void {
    this.blockChain.remove(blockId);
    const op = this.opAdapter.remove(blockId);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
  }

  public move(blockId: string, newParentId: string, newPrevId: string): void {
    this.blockChain.move(blockId, newParentId, newPrevId);
    const op = this.opAdapter.move(blockId, newParentId, newPrevId);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
  }

  public moveBulk(startBlockId: string, endBlockId: string, newParentId: string, newPrevId: string): void {
    this.blockChain.moveBulk(startBlockId, endBlockId, newParentId, newPrevId);
    const op = this.opAdapter.moveBulk(startBlockId, endBlockId, newParentId, newPrevId);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
  }

  public setSelection(blockId: string, data: any) {
    this.selection.focusBlock(blockId, data)
  }


  private applyOp(op: Operation): void {
    // Apply the prependChild operation to the local document
    // ...
    this.appliedOps.push(op);
    this.version++;
  }

  private receiveOps(ops: Operation[]): void {
    // Apply the incoming operations to the local document
    ops.sort((a, b) => a.version! - b.version!);
    for (const op of ops) {
      this.applyOp(op);
    }
  }

  private resolveConflict(): void {
    // Implement conflict resolution logic here
  }

  public sendOps() {
    // Send the pending operations to the server
    const promise = new Promise(resolve => {
      setTimeout(() => {
        console.log('==== sync pending ops ====', [...this.pendingOps]);
        this.pendingOps.length = 0;
        resolve(true);
      }, 1000);
    })
  }

  private newBlockMovePos(newBlock: Block) {
    // new block
    this.pendingOps.push({
     ...this.opAdapter.newBlock(newBlock.id, {
       type: newBlock.type,
       data: newBlock.data
     }),
     version: this.version
   });
   // move block
   this.pendingOps.push({
     ...this.opAdapter.move(newBlock.id, newBlock.parent?.id || '', newBlock.prev?.id || ''),
     version: this.version
   });
 }

}
