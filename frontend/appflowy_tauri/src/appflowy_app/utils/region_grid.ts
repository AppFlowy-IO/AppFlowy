export interface BlockPosition {
  id: string;
  x: number;
  y: number;
  height: number;
  width: number;
}

interface Rectangle {
  x: number;
  y: number;
  height: number;
  width: number;
}

export class RegionGrid {
  private readonly gridSize: number;
  private readonly grid: Map<string, BlockPosition[]>;
  private readonly blockKeysMap: Map<string, string[]>;

  constructor(gridSize: number) {
    this.gridSize = gridSize;
    this.grid = new Map();
    this.blockKeysMap = new Map();
  }

  private getKeys(x: number, y: number, width: number, height: number): string[] {
    const keys: string[] = [];

    for (let i = Math.floor(x / this.gridSize); i <= Math.floor((x + width) / this.gridSize); i++) {
      for (let j = Math.floor(y / this.gridSize); j <= Math.floor((y + height) / this.gridSize); j++) {
        keys.push(`${i},${j}`);
      }
    }

    return keys;
  }

  addBlock(block: BlockPosition): void {
    const keys = this.getKeys(block.x, block.y, block.width, block.height);

    this.blockKeysMap.set(block.id, keys);

    for (const key of keys) {
      if (!this.grid.has(key)) {
        this.grid.set(key, []);
      }

      this.grid.get(key)?.push(block);
    }
  }

  hasBlock(id: string) {
    return this.blockKeysMap.has(id);
  }

  updateBlock(block: BlockPosition): void {
    if (this.hasBlock(block.id)) {
      this.removeBlock(block);
    }

    this.addBlock(block);
  }

  removeBlock(block: BlockPosition): void {
    const keys = this.blockKeysMap.get(block.id) || [];

    for (const key of keys) {
      const blocks = this.grid.get(key);

      if (blocks) {
        const index = blocks.findIndex((b) => b.id === block.id);

        if (index !== -1) {
          blocks.splice(index, 1);

          if (blocks.length === 0) {
            this.grid.delete(key);
          }
        }
      }
    }
  }

  getIntersectingBlocks(rect: Rectangle): BlockPosition[] {
    const blocks = new Set<BlockPosition>();
    const keys = this.getKeys(rect.x, rect.y, rect.width, rect.height);

    for (const key of keys) {
      if (this.grid.has(key)) {
        this.grid.get(key)?.forEach((block) => {
          if (
            rect.x < block.x + block.width &&
            rect.x + rect.width > block.x &&
            rect.y < block.y + block.height &&
            rect.y + rect.height > block.y
          )
            blocks.add(block);
        });
      }
    }

    return Array.from(blocks);
  }
}
