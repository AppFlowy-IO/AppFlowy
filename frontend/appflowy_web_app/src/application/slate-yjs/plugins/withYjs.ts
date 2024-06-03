import { CollabOrigin, YjsEditorKey, YSharedRoot } from '@/application/collab.type';
import { applyToYjs } from '@/application/slate-yjs/utils/applyToYjs';
import { Editor, Operation, Descendant } from 'slate';
import Y, { YEvent, Transaction } from 'yjs';
import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';

type LocalChange = {
  op: Operation;
  slateContent: Descendant[];
};

export interface YjsEditor extends Editor {
  connect: () => void;
  disconnect: () => void;
  sharedRoot: YSharedRoot;
  applyRemoteEvents: (events: Array<YEvent<YSharedRoot>>, transaction: Transaction) => void;
  flushLocalChanges: () => void;
  storeLocalChange: (op: Operation) => void;
}

const connectSet = new WeakSet<YjsEditor>();

const localChanges = new WeakMap<YjsEditor, LocalChange[]>();

// eslint-disable-next-line @typescript-eslint/no-redeclare
export const YjsEditor = {
  connected(editor: YjsEditor): boolean {
    return connectSet.has(editor);
  },

  connect(editor: YjsEditor): void {
    editor.connect();
  },

  disconnect(editor: YjsEditor): void {
    editor.disconnect();
  },

  applyRemoteEvents(editor: YjsEditor, events: Array<YEvent<YSharedRoot>>, transaction: Transaction): void {
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
    localOrigin: CollabOrigin;
  }
): T & YjsEditor {
  const { localOrigin = CollabOrigin.Local } = opts ?? {};
  const e = editor as T & YjsEditor;
  const { apply, onChange } = e;

  e.sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  const initializeDocumentContent = () => {
    const content = yDocToSlateContent(doc);

    if (!content) {
      return;
    }

    e.children = content.children;

    console.log('initializeDocumentContent', doc.getMap(YjsEditorKey.data_section).toJSON(), e.children);
    Editor.normalize(editor, { force: true });
  };

  const applyIntercept = (op: Operation) => {
    if (YjsEditor.connected(e)) {
      YjsEditor.storeLocalChange(e, op);
    }

    apply(op);
  };

  const applyRemoteIntercept = (op: Operation) => {
    apply(op);
  };

  e.applyRemoteEvents = (_events: Array<YEvent<YSharedRoot>>, _: Transaction) => {
    // Flush local changes to ensure all local changes are applied before processing remote events
    YjsEditor.flushLocalChanges(e);
    // Replace the apply function to avoid storing remote changes as local changes
    e.apply = applyRemoteIntercept;

    // Initialize or update the document content to ensure it is in the correct state before applying remote events
    initializeDocumentContent();

    // Restore the apply function to store local changes after applying remote changes
    e.apply = applyIntercept;
  };

  const handleYEvents = (events: Array<YEvent<YSharedRoot>>, transaction: Transaction) => {
    if (transaction.origin === CollabOrigin.Remote) {
      YjsEditor.applyRemoteEvents(e, events, transaction);
    }
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
        applyToYjs(doc, { children: change.slateContent }, change.op);
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
