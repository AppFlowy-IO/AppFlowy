import { CollabOrigin, YjsEditorKey, YSharedRoot } from '@/application/collab.type';
import { applySlateOp } from '@/application/slate-yjs/utils/applySlateOpts';
import { translateYjsEvent } from 'src/application/slate-yjs/utils/translateYjsEvent';
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
  localOrigin: CollabOrigin = CollabOrigin.Local
): T & YjsEditor {
  const e = editor as T & YjsEditor;
  const { apply, onChange } = e;

  e.sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  e.applyRemoteEvents = (events: Array<YEvent<YSharedRoot>>, _: Transaction) => {
    YjsEditor.flushLocalChanges(e);

    Editor.withoutNormalizing(editor, () => {
      events.forEach((event) => {
        translateYjsEvent(e.sharedRoot, editor, event).forEach((op) => {
          // apply remote events to slate, don't call e.apply here because e.apply has been overridden.
          apply(op);
        });
      });
    });
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

    const content = yDocToSlateContent(doc, true);

    if (!content) {
      return;
    }

    console.log(content);

    e.sharedRoot.observeDeep(handleYEvents);
    e.children = content.children;
    Editor.normalize(editor, { force: true });
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
        applySlateOp(doc, { children: change.slateContent }, change.op);
      });
    }, localOrigin);
  };

  e.apply = (op) => {
    if (YjsEditor.connected(e)) {
      YjsEditor.storeLocalChange(e, op);
    }

    apply(op);
  };

  e.onChange = () => {
    if (YjsEditor.connected(e)) {
      YjsEditor.flushLocalChanges(e);
    }

    onChange();
  };

  return e;
}
