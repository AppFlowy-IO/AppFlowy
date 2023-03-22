import { RegionGrid, BlockPosition } from './region_grid';
export class BlockPositionManager {
  private regionGrid: RegionGrid;
  private viewportBlocks: Set<string> = new Set();
  private blockPositions: Map<string, BlockPosition> = new Map();
  private observer: IntersectionObserver;
  private container: HTMLDivElement | null = null;

  constructor(container: HTMLDivElement) {
    this.container = container;
    this.regionGrid = new RegionGrid(container.offsetHeight);
    this.observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        const blockId = entry.target.getAttribute('data-block-id');
        if (!blockId) return;
        if (entry.isIntersecting) {
          this.updateBlockPosition(blockId);
          this.viewportBlocks.add(blockId);
        } else {
          this.viewportBlocks.delete(blockId);
        }
      }
    }, { root: container });
  }

  observeBlock(node: HTMLDivElement) {
    this.observer.observe(node);
    return {
      unobserve: () => this.observer.unobserve(node),
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

  destroy() {
    this.container = null;
    this.observer.disconnect();
  }

}