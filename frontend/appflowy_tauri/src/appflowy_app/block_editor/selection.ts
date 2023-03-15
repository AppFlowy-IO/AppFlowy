export class SelectionManager {
  private selectedBlocks: Set<string> = new Set();
  private focusBlockId = '';
  private blockSelection?: any;

  getFocusBlockSelection() {
    return {
      focusBlockId: this.focusBlockId,
      selection: this.blockSelection
    }
  }

  focusBlockStart(blockId: string) {
    this.focusBlockId = blockId;
    this.focusBlock(blockId, {
      focus: {
        path: [0, 0],
        offset: 0,
      },
      anchor: {
        path: [0, 0],
        offset: 0,
      },
    })
  }

  focusBlock(blockId: string, selection: any) {
    this.focusBlockId = blockId;
    this.blockSelection = selection;
  }

  destroy() {
    this.selectedBlocks.clear();
    this.focusBlockId = '';
    this.blockSelection = undefined;
  }
}