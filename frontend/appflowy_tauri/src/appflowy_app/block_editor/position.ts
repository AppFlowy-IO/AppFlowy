/**
 * This file exports the `BlockPositionManager` class.
 *
 * The `BlockPositionManager` is responsible for managing the position of blocks on the screen.
 * It uses an LRU cache to store the position of blocks, and updates the position when necessary.
 * It also observes the intersection of blocks with the viewport, and updates the position of the blocks when they intersect.
 */

import { LRUCache } from "../utils/LRU";
import { calculateViewportBlockMaxCount } from "../utils/block";
import { debounce } from "../utils/tool";
import { TreeNode } from './tree_node';

/**
 * Interface representing the position of a block on the screen.
 */
export interface BlockPosition {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * The number of milliseconds to wait before updating the block position.
 */
const UPDATE_BLOCK_POSITION_DELAY = 500;

/**
 * The `BlockPositionManager` class is responsible for managing the position of blocks on the screen.
 */
export class BlockPositionManager {

  /**
   * The cache of block positions.
   */
  private blockPositions: LRUCache<BlockPosition>;

  /**
   * The set of block IDs that need to be updated.
   */
  private updateQueue: Set<string> = new Set();

  /**
   * A debounced function that adds update tasks to the queue.
   */
  private debounceUpdatePositions = debounce(() => this.addUpdateTask(), UPDATE_BLOCK_POSITION_DELAY);

  /**
   * The set of block IDs that are currently in the viewport.
   */
  private viewportBlocks: Set<string> = new Set();

  /**
   * Creates a new `BlockPositionManager`.
   */
  constructor() {
    const blockPositionsCapacity = calculateViewportBlockMaxCount();
    this.blockPositions = new LRUCache<BlockPosition>(blockPositionsCapacity);
  }

  /**
   * Observes a block and updates its position when it intersects with the viewport.
   * @param node - The tree node corresponding to the block.
   * @param el - The HTML element corresponding to the block.
   * @returns An object with a `disconnect` method that can be called to stop observing the block.
   */
  public observeBlock(node: TreeNode, el: HTMLDivElement) {
    const blockId = node.id;

    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          this.viewportBlocks.add(blockId);
          this.updateBlock(blockId);
        } else {
          this.updateQueue.delete(blockId);
          this.viewportBlocks.delete(blockId)
        }
      }
    });

    observer.observe(el);
    return {
      disconnect: () => {
        this.removeBlock(node.id);
        observer.disconnect()
      }
    };
  }

  /**
   * Gets the position of a block.
   * @param blockId - The ID of the block.
   * @returns The position of the block, or `null` if the block is not found.
   */
  public getBlockPosition(blockId: string): BlockPosition | null {
    let blockPosition = this.blockPositions.get(blockId) || null;
    if (!blockPosition) {
      blockPosition = this.updateBlockPosition(blockId);
    }

    return blockPosition;
  }

  updateBlock(blockId: string) {
    if (this.updateQueue.has(blockId)) {
      return;
    }

    this.updateQueue.add(blockId);
    this.debounceUpdatePositions();
  }

  destroy() {
    this.blockPositions.clear();
    this.viewportBlocks.clear();
    this.updateQueue.clear();
  }


  /**
   * Adds an update task to the queue.
   */
  private addUpdateTask = () => {
    this.updateQueue.forEach(id => {
      this.updateBlockPosition(id);
      this.updateQueue.delete(id);
    })
  }


  /**
 * Removes the block with the given blockId.
 * @param {string} blockId - The id of the block to be removed.
 */
  private removeBlock(blockId: string) {
    this.updateQueue.delete(blockId);
    this.viewportBlocks.delete(blockId)
    this.blockPositions.delete(blockId);
  }


  /**
   * Updates the position of the block with the given blockId.
   * @param {string} blockId - The id of the block to be updated.
   * @returns {BlockPosition | null} The updated block position, or null if the block was not found.
   */
  private updateBlockPosition(blockId: string) {
    const oldPosition = this.blockPositions.get(blockId);
    const position = this.getBlockPositionFromDocument(blockId);

    if (!oldPosition || !position ||
      oldPosition.height !== position.height ||
      oldPosition.y !== position.y) {
      this.updateViewportBlocks();
    }

    if (position) this.blockPositions.put(blockId, position);
    return position;
  }


  /**
 * Updates the viewport blocks.
 */
  public updateViewportBlocks() {
    let reUpdate = false;
    this.viewportBlocks.forEach(key => {
      if (!this.updateQueue.has(key)) {
        reUpdate = true;
        this.updateQueue.add(key)
      }
    });
    if (reUpdate) {
      this.debounceUpdatePositions();
    }
  }

  private getBlockPositionFromDocument(blockId: string): BlockPosition | null {
    const position = { id: blockId, x: 0, y: 0, width: 0, height: 0 };

    const el = document.querySelector(`[data-block-id=${blockId}]`) as HTMLElement;
    if (!el) {
      return null;
    }

    const rect = el.getBoundingClientRect();
    const scrollContainer = document.querySelector('.doc-scroller-container');
    Object.assign(position, {
      x: rect.left,
      y: rect.top + scrollContainer!.scrollTop,
      height: rect.height,
      width: rect.width
    });

    return position;
  }
}
