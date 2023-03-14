import { Block } from './block';
import { BlockChain } from './block_chain';
import { Operation, OPAdapter } from './op_adapter';

/**
 * BlockEditorSync is a class that synchronizes changes made to a block chain with a server.
 * It allows for adding, removing, and moving blocks in the chain, and sends pending operations to the server.
 */
export class BlockEditorSync {
  private version = 0;
  private pendingOps: Operation[] = [];
  private appliedOps: Operation[] = [];
  private opAdapter: OPAdapter = new OPAdapter();
  
  constructor(private server: any, private blockChain: BlockChain) {

  }

  public prependChild(parentId: string, content: any): void {
    const newBlock = this.blockChain.prependChild(parentId, content);
    if (!newBlock) return;
    this.newBlockMovePos(newBlock);
    this.sendOps();
  }

  public addSibling(prevId: string, content: any): void {
    const newBlock = this.blockChain.addSibling(prevId, content);
    if (!newBlock) return;
    this.newBlockMovePos(newBlock);
    this.sendOps();
  }

  public remove(blockId: string): void {
    this.blockChain.remove(blockId);
    const op = this.opAdapter.remove(blockId);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
    this.sendOps();
  }

  public move(blockId: string, newParentId: string, newPrevId: string): void {
    this.blockChain.move(blockId, newParentId, newPrevId);
    const op = this.opAdapter.move(blockId, newParentId, newPrevId);
    this.pendingOps.push({
      ...op,
      version: this.version
    });
    this.sendOps();
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

  private sendOps(): void {
    // Send the pending operations to the server
    console.log('==== sync pending ops ====', this.pendingOps);
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
