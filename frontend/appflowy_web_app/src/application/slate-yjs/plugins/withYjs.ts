import { translateYEvents } from '@/application/slate-yjs/utils/applyToSlate';
import { CollabOrigin, YjsEditorKey, YSharedRoot } from '@/application/types';
import { applyToYjs } from '@/application/slate-yjs/utils/applyToYjs';
import { Editor, Operation, Descendant, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';
import Y, { YEvent, Transaction } from 'yjs';
import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';

type LocalChange = {
  op: Operation;
  slateContent: Descendant[];
};

export interface YjsEditor extends Editor {
  readOnly: boolean;
  isYjsEditor: (value: unknown) => value is YjsEditor;
  connect: () => void;
  disconnect: () => void;
  sharedRoot: YSharedRoot;
  applyRemoteEvents: (events: Array<YEvent>, transaction: Transaction) => void;
  flushLocalChanges: () => void;
  storeLocalChange: (op: Operation) => void;
  interceptLocalChange: boolean;
  uploadFile?: (file: File) => Promise<string>;
}

const connectSet = new WeakSet<YjsEditor>();

const localChanges = new WeakMap<YjsEditor, LocalChange[]>();

// eslint-disable-next-line @typescript-eslint/no-redeclare
export const YjsEditor = {
  isYjsEditor(value: unknown): value is YjsEditor {
    return (
      Editor.isEditor(value) &&
      'connect' in value &&
      'disconnect' in value &&
      'sharedRoot' in value &&
      'applyRemoteEvents' in value &&
      'flushLocalChanges' in value &&
      'storeLocalChange' in value
    );
  },
  connected(editor: YjsEditor): boolean {
    return connectSet.has(editor);
  },

  connect(editor: YjsEditor): void {
    editor.connect();
  },

  disconnect(editor: YjsEditor): void {
    editor.disconnect();
  },

  applyRemoteEvents(editor: YjsEditor, events: Array<YEvent>, transaction: Transaction): void {
    editor.applyRemoteEvents(events, transaction);
  },

  localChanges(editor: YjsEditor): LocalChange[] {
    return localChanges.get(editor) ?? [];
  },

  storeLocalChange(editor: YjsEditor, op: Operation): void {
    editor.storeLocalChange(op);
  },

  flushLocalChanges(editor: YjsEditor): void {
    editor.flushLocalChanges();
  },
};

export function withYjs<T extends Editor>(
  editor: T,
  doc: Y.Doc,
  opts?: {
    readOnly: boolean;
    localOrigin: CollabOrigin;
    readSummary?: boolean;
    onContentChange?: (content: Descendant[]) => void;
    uploadFile?: (file: File) => Promise<string>;
  },
): T & YjsEditor {
  const { uploadFile, localOrigin = CollabOrigin.Local, readSummary, onContentChange, readOnly = true } = opts ?? {};
  const e = editor as T & YjsEditor;
  const { apply, onChange } = e;

  e.interceptLocalChange = false;
  e.readOnly = readOnly;
  e.uploadFile = uploadFile;

  e.sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  const initializeDocumentContent = () => {
    const content = yDocToSlateContent(doc);

    if (!content) {
      return;
    }

    const selection = e.selection;

    if (readSummary) {
      e.children = content.children.slice(0, 10);
    } else {
      e.children = content.children;
    }

    if (selection && !ReactEditor.hasRange(editor, selection)) {
      try {
        Transforms.select(e, Editor.start(editor, [0]));

      } catch (e) {
        console.error(e);
        editor.deselect();
      }
    }

    onContentChange?.(content.children);
    console.log('===initializeDocumentContent', e.children);
    Editor.normalize(e, { force: true });
  };

  const applyIntercept = (op: Operation) => {
    if (YjsEditor.connected(e) && !e.interceptLocalChange) {
      YjsEditor.storeLocalChange(e, op);
    }

    apply(op);
  };

  e.applyRemoteEvents = (events: Array<YEvent>, transaction: Transaction) => {
    console.time('applyRemoteEvents');
    // Flush local changes to ensure all local changes are applied before processing remote events
    YjsEditor.flushLocalChanges(e);
    // Replace the apply function to avoid storing remote changes as local changes
    e.interceptLocalChange = true;

    // Initialize or update the document content to ensure it is in the correct state before applying remote events
    if (transaction.origin === CollabOrigin.Remote) {
      initializeDocumentContent();
    } else {
      const selection = editor.selection;

      Editor.withoutNormalizing(e, () => {
        translateYEvents(e, events);
      });
      if (selection) {
        if (!ReactEditor.hasRange(editor, selection)) {
          editor.deselect();
        } else {
          e.select(selection);
        }
      }
    }

    // Restore the apply function to store local changes after applying remote changes
    e.interceptLocalChange = false;
    console.timeEnd('applyRemoteEvents');
  };

  const handleYEvents = (events: Array<YEvent>, transaction: Transaction) => {
    if (transaction.origin === CollabOrigin.Local) return;
    YjsEditor.applyRemoteEvents(e, events, transaction);

  };

  e.connect = () => {
    if (YjsEditor.connected(e)) {
      throw new Error('Already connected');
    }

    initializeDocumentContent();
    e.sharedRoot.observeDeep(handleYEvents);
    connectSet.add(e);
  };

  e.disconnect = () => {
    if (!YjsEditor.connected(e)) {
      throw new Error('Not connected');
    }

    e.sharedRoot.unobserveDeep(handleYEvents);
    connectSet.delete(e);
  };

  e.storeLocalChange = (op) => {
    const changes = localChanges.get(e) ?? [];

    localChanges.set(e, [...changes, { op, slateContent: e.children }]);
  };

  e.flushLocalChanges = () => {
    const changes = YjsEditor.localChanges(e);

    localChanges.delete(e);
    // parse changes and apply to ydoc
    doc.transact(() => {
      changes.forEach((change) => {
        applyToYjs(doc, editor, change.op, change.slateContent);
      });
    }, localOrigin);
  };

  e.apply = applyIntercept;

  e.onChange = () => {
    if (YjsEditor.connected(e)) {
      YjsEditor.flushLocalChanges(e);
    }

    onChange();
  };

  return e;
}
