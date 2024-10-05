import { getDocument } from '@/application/slate-yjs/utils/yjsOperations';
import { relativeRangeToSlateRange, slateRangeToRelativeRange } from '@/application/slate-yjs/utils/positions';
import { CollabOrigin } from '@/application/types';
import { Editor, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';
import * as Y from 'yjs';
import { YjsEditor } from './withYjs';
import { HistoryStackItem, RelativeRange } from '../types';

const LAST_SELECTION: WeakMap<Editor, RelativeRange | null> = new WeakMap();

export type YHistoryEditor = YjsEditor & {
  undoManager: Y.UndoManager;
  undo: () => void;
  redo: () => void;
};
// eslint-disable-next-line @typescript-eslint/no-redeclare
export const YHistoryEditor = {
  isYHistoryEditor (value: unknown): value is YHistoryEditor {
    return (
      YjsEditor.isYjsEditor(value) &&
      'undoManager' in value &&
      typeof (value as YHistoryEditor).undo === 'function' &&
      typeof (value as YHistoryEditor).redo === 'function'
    );
  },

  canUndo (editor: YHistoryEditor) {
    return editor.undoManager.undoStack.length > 0;
  },

  canRedo (editor: YHistoryEditor) {
    return editor.undoManager.redoStack.length > 0;
  },
};

export function withYHistory<T extends YjsEditor> (
  editor: T,
): T & YHistoryEditor {
  const e = editor as T & YHistoryEditor;

  if (e.readOnly) {
    return e;
  }

  e.undoManager = new Y.UndoManager(getDocument(e.sharedRoot), {
    trackedOrigins: new Set([CollabOrigin.Local, null]),
    captureTimeout: 200,
  });

  const { onChange } = e;

  e.onChange = () => {
    onChange();

    const selection = e.selection;

    try {
      const storeSelection = selection && slateRangeToRelativeRange(e.sharedRoot, e, selection);

      LAST_SELECTION.set(
        e,
        storeSelection,
      );
    } catch (e) {
      console.error(e);
    }
  };

  const handleStackItemAdded = ({
    stackItem,
  }: {
    stackItem: HistoryStackItem;
    type: 'redo' | 'undo';
  }) => {
    try {
      stackItem.meta.set(
        'selection',
        e.selection && slateRangeToRelativeRange(e.sharedRoot, e, e.selection),
      );

      stackItem.meta.set('selectionBefore', LAST_SELECTION.get(e));
    } catch (e) {
      // console.error(e);
    }

  };

  const handleStackItemPopped = ({
    stackItem,
  }: {
    stackItem: HistoryStackItem;
    type: 'redo' | 'undo';
  }) => {
    const relativeSelection = stackItem.meta.get(
      'selectionBefore',
    ) as RelativeRange | null;

    if (!relativeSelection) {
      return;
    }

    const selection = relativeRangeToSlateRange(
      e.sharedRoot,
      e,
      relativeSelection,
    );

    if (!selection || !ReactEditor.hasRange(editor, selection)) {
      const startPoint = Editor.start(e, [0]);

      Transforms.select(e, startPoint);
      return;
    }

    Transforms.select(e, selection);
  };

  const { connect } = e;

  e.connect = () => {
    connect();
    e.undoManager.on('stack-item-added', handleStackItemAdded);
    e.undoManager.on('stack-item-popped', handleStackItemPopped);
  };

  const { disconnect } = e;

  e.disconnect = () => {
    e.undoManager.off('stack-item-added', handleStackItemAdded);
    e.undoManager.off('stack-item-popped', handleStackItemPopped);
    disconnect();
  };

  e.undo = () => {
    if (YjsEditor.connected(e)) {
      YjsEditor.flushLocalChanges(e);
      e.undoManager.undo();
    }
  };

  e.redo = () => {
    if (YjsEditor.connected(e)) {
      YjsEditor.flushLocalChanges(e);
      e.undoManager.redo();
    }
  };

  return e;
}