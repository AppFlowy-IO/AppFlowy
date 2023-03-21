import { BackendOp, LocalOp } from '$app/interfaces';
import { OpAdapter } from './op_adapter';

/**
 * BlockEditorSync is a class that synchronizes changes made to a block chain with a server.
 * It allows for adding, removing, and moving blocks in the chain, and sends pending operations to the server.
 */
export class BlockEditorSync {
  private version = 0;
  private opAdapter: OpAdapter;
  private pendingOps: BackendOp[] = [];
  private appliedOps: LocalOp[] = [];
  
  constructor() {
    this.opAdapter = new OpAdapter();
  }

  private applyOp(op: BackendOp): void {
    const localOp = this.opAdapter.toLocalOp(op);
    this.appliedOps.push(localOp);
  }

  private receiveOps(ops: BackendOp[]): void {
    // Apply the incoming operations to the local document
    ops.sort((a, b) => a.version - b.version);
    for (const op of ops) {
      this.applyOp(op);
    }
  }

  private resolveConflict(): void {
    // Implement conflict resolution logic here
  }

  public sendOps(ops: {
    type: LocalOp["type"];
    data: LocalOp["data"]
  }[]) {
    const backendOps = ops.map(op => this.opAdapter.toBackendOp({
      ...op,
      version: this.version
    }));
    this.pendingOps.push(...backendOps);
    // Send the pending operations to the server
    console.log('==== sync pending ops ====', [...this.pendingOps]);
  }

}
