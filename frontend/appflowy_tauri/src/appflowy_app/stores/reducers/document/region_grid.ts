export interface BlockPosition {
  id: string;
  x: number;
  y: number;
  height: number;
  width: number;
}
interface BlockRegion {
  regionX: number;
  regionY: number;
  blocks: BlockPosition[];
}

export class RegionGrid {
  private regions: BlockRegion[][];
  private regionSize: number;
  private blocks = new Map();

  constructor(regionSize: number) {
    this.regionSize = regionSize;
    this.regions = [];
  }

  addBlock(blockPosition: BlockPosition) {
    const regionX = Math.floor(blockPosition.x / this.regionSize);
    const regionY = Math.floor(blockPosition.y / this.regionSize);

    let region = this.regions[regionY]?.[regionX];
    if (!region) {
      region = {
        regionX,
        regionY,
        blocks: []
      };
      if (!this.regions[regionY]) {
        this.regions[regionY] = [];
      }
      this.regions[regionY][regionX] = region;
    }
    this.blocks.set(blockPosition.id, blockPosition);
    region.blocks.push(blockPosition);
  }

  updateBlock(blockId: string, position: BlockPosition) {
    const prevPosition = this.blocks.get(blockId);
    if (prevPosition && prevPosition.x === position.x &&
      prevPosition.y === position.y &&
      prevPosition.height === position.height &&
      prevPosition.width === position.width) {
      return;
    }
    this.blocks.set(blockId, position);
    this.removeBlock(blockId);
    this.addBlock(position);
  }
  
  removeBlock(blockId: string) {
    for (const rows of this.regions) {
      for (const region of rows) {
        if (!region) return;
        const blockIndex = region.blocks.findIndex(b => b.id === blockId);
        if (blockIndex !== -1) {
          region.blocks.splice(blockIndex, 1);
          return;
        }
      }
    }
    this.blocks.delete(blockId);
  }
  

  getIntersectBlocks(startX: number, startY: number, endX: number, endY: number): BlockPosition[] {
    const selectedBlocks: BlockPosition[] = [];

    const startRegionX = Math.floor(startX / this.regionSize);
    const startRegionY = Math.floor(startY / this.regionSize);
    const endRegionX = Math.floor(endX / this.regionSize);
    const endRegionY = Math.floor(endY / this.regionSize);

    for (let y = startRegionY; y <= endRegionY; y++) {
      for (let x = startRegionX; x <= endRegionX; x++) {
        const region = this.regions[y]?.[x];
        if (region) {
          for (const block of region.blocks) {
            if (block.x + block.width - 1 >= startX && block.x <= endX &&
              block.y + block.height - 1 >= startY && block.y <= endY) {
              selectedBlocks.push(block);
            }
          }
        }
      }
    }

    return selectedBlocks;
  }
}
