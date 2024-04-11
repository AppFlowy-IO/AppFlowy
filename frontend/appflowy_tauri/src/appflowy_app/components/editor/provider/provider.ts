import * as Y from 'yjs';

import { DataClient } from '$app/components/editor/provider/data_client';
import { YDelta } from '$app/components/editor/provider/types/y_event';
import { YEvents2BlockActions } from '$app/components/editor/provider/utils/action';
import { EventEmitter } from 'events';

const REMOTE_ORIGIN = 'remote';

export class Provider extends EventEmitter {
  document: Y.Doc = new Y.Doc();
  sharedType: Y.XmlText | null = null;
  dataClient: DataClient;
  // get origin data after document updated
  backupDoc: Y.Doc = new Y.Doc();
  constructor(public id: string) {
    super();
    this.dataClient = new DataClient(id);
    this.document.on('update', this.documentUpdate);
  }

  initialDocument = async (includeRoot = true) => {
    const sharedType = this.document.get('sharedType', Y.XmlText) as Y.XmlText;
    // Load the initial value into the yjs document
    const delta = await this.dataClient.getInsertDelta(includeRoot);

    sharedType.applyDelta(delta);

    const rootId = this.dataClient.rootId as string;
    const root = delta[0].insert as Y.XmlText;
    const data = root.getAttribute('data');

    sharedType.setAttribute('blockId', rootId);
    sharedType.setAttribute('data', data);

    this.sharedType = sharedType;
    this.sharedType?.observeDeep(this.onChange);
    this.emit('ready');
  };

  connect() {
    this.dataClient.on('change', this.onRemoteChange);
    return;
  }

  disconnect() {
    this.dataClient.off('change', this.onRemoteChange);
    this.dataClient.disconnect();
    this.sharedType?.unobserveDeep(this.onChange);
    this.sharedType = null;
  }

  onChange = (events: Y.YEvent<Y.XmlText>[], transaction: Y.Transaction) => {
    if (transaction.origin === REMOTE_ORIGIN) {
      return;
    }

    if (!this.sharedType || !events.length) return;
    // transform events to actions
    this.dataClient.emit('update', YEvents2BlockActions(this.backupDoc, events));
  };

  onRemoteChange = (delta: YDelta) => {
    if (!delta.length) return;

    this.document.transact(() => {
      this.sharedType?.applyDelta(delta);
    }, REMOTE_ORIGIN);
  };

  documentUpdate = (update: Uint8Array) => {
    Y.applyUpdate(this.backupDoc, update);
  };
}
