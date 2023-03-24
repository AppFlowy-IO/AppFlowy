import { RegionGrid, BlockPosition } from './region_grid';
export class BlockPositionManager {
  private regionGrid: RegionGrid;
  private viewportBlocks: Set<string> = new Set();
  private blockPositions: Map<string, BlockPosition> = new Map();
  private container: HTMLDivElement | null = null;

  constructor(container: HTMLDivElement) {
    this.container = container;
    this.regionGrid = new RegionGrid(container.offsetHeight);
  }

  isInViewport(nodeId: string) {
    return this.viewportBlocks.has(nodeId);
  }

  observeBlock(node: HTMLDivElement) {
    const blockId = node.getAttribute('data-block-id');
    if (blockId) {
      this.updateBlockPosition(blockId);
      this.viewportBlocks.add(blockId);
    }
    return {
      unobserve: () => {
        if (blockId) this.viewportBlocks.delete(blockId);
      },
    }
  }

  getBlockPosition(blockId: string) {
    if (!this.blockPositions.has(blockId)) {
      this.updateBlockPosition(blockId);
    }
    return this.blockPositions.get(blockId);
  }

  updateBlockPosition(blockId: string) {
    if (!this.container) return;
    const node = document.querySelector(`[data-block-id=${blockId}]`) as HTMLDivElement;
    if (!node) return;
    const rect = node.getBoundingClientRect();
    const position = {
      id: blockId,
      x: rect.x,
      y: rect.y + this.container.scrollTop,
      height: rect.height,
      width: rect.width
    };
    const prevPosition =  this.blockPositions.get(blockId);
    if (prevPosition && prevPosition.x === position.x &&
      prevPosition.y === position.y &&
      prevPosition.height === position.height &&
      prevPosition.width === position.width) {
      return;
    }
    this.blockPositions.set(blockId, position);
    this.regionGrid.removeBlock(blockId);
    this.regionGrid.addBlock(position);
  }

  getIntersectBlocks(startX: number, startY: number, endX: number, endY: number): BlockPosition[] {
    return this.regionGrid.getIntersectBlocks(startX, startY, endX, endY);
  }

  getViewportBlockByPoint(x: number, y: number): BlockPosition | null {
    let blockPosition: BlockPosition | null = null;
    this.viewportBlocks.forEach(id => {
      this.updateBlockPosition(id);
      const block = this.blockPositions.get(id);
      if (!block) return;
      
      if (block.x + block.width - 1 >= x &&
        block.y + block.height - 1 >= y && block.y <= y) {
          if (!blockPosition || block.y > blockPosition.y) {
            blockPosition = block;
          }
      }
    });
    return blockPosition;
  }


  destroy() {
    this.container = null;
  }

}