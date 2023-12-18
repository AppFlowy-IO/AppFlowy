import * as Y from 'yjs';

import { DataClient } from '$app/components/editor/provider/data_client';
import { convertToIdList, fillIdRelationMap } from '$app/components/editor/provider/utils/relation';
import { YDelta } from '$app/components/editor/provider/types/y_event';
import { YEvents2BlockActions } from '$app/components/editor/provider/utils/action';
import { EventEmitter } from 'events';

const REMOTE_ORIGIN = 'remote';

export class Provider extends EventEmitter {
  document: Y.Doc = new Y.Doc();
  // id order
  idList: Y.XmlText = this.document.get('idList', Y.XmlText) as Y.XmlText;
  // id -> parentId
  idRelationMap: Y.Map<string> = this.document.getMap('idRelationMap');
  sharedType: Y.XmlText | null = null;
  dataClient: DataClient;
  constructor(public id: string) {
    super();
    this.dataClient = new DataClient(id);
    void this.initialDocument();
  }

  initialDocument = async () => {
    const sharedType = this.document.get('local', Y.XmlText) as Y.XmlText;

    // Load the initial value into the yjs document
    const delta = await this.dataClient.getInsertDelta();

    sharedType.applyDelta(delta);

    this.idList.applyDelta(convertToIdList(delta));
    delta.forEach((op) => {
      if (op.insert instanceof Y.XmlText) {
        fillIdRelationMap(op.insert, this.idRelationMap);
      }
    });

    sharedType.setAttribute('blockId', this.dataClient.rootId);

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
    this.dataClient.emit('update', YEvents2BlockActions(this.sharedType, events));
  };

  onRemoteChange = (delta: YDelta) => {
    if (!delta.length) return;

    this.document.transact(() => {
      this.sharedType?.applyDelta(delta);
    }, REMOTE_ORIGIN);
  };
}
