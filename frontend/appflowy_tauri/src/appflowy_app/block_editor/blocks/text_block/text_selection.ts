export class TextBlockSelectionManager {
  private focusId = '';
  private selection?: any;

  getFocusSelection() {
    return {
      focusId: this.focusId,
      selection: this.selection
    }
  }

  focusStart(blockId: string) {
    this.focusId = blockId;
    this.setSelection(blockId, {
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

  setSelection(blockId: string, selection: any) {
    this.focusId = blockId;
    this.selection = selection;
  }

  destroy() {
    this.focusId = '';
    this.selection = undefined;
  }
}