import { applyActions, closeDocument, openDocument } from '$app/application/document/document.service';
import { slateNodesToInsertDelta } from '@slate-yjs/core';
import { convertToSlateValue } from '$app/components/editor/provider/utils/convert';
import { EventEmitter } from 'events';
import { BlockActionPB, DocEventPB, DocumentNotification } from '@/services/backend';
import { AsyncQueue } from '$app/utils/async_queue';
import { subscribeNotification } from '$app/application/notification';
import { YDelta } from '$app/components/editor/provider/types/y_event';
import { DocEvent2YDelta } from '$app/components/editor/provider/utils/delta';

export class DataClient extends EventEmitter {
  private queue: AsyncQueue<ReturnType<typeof BlockActionPB.prototype.toObject>[]>;
  private unsubscribe: Promise<() => void>;
  public rootId?: string;

  constructor(private id: string) {
    super();
    this.queue = new AsyncQueue(this.sendActions);
    this.unsubscribe = subscribeNotification(DocumentNotification.DidReceiveUpdate, this.sendMessage);

    this.on('update', this.handleReceiveMessage);
  }

  public disconnect() {
    this.off('update', this.handleReceiveMessage);
    void closeDocument(this.id);
    void this.unsubscribe.then((unsubscribe) => unsubscribe());
  }

  public async getInsertDelta(includeRoot = true) {
    const data = await openDocument(this.id);

    this.rootId = data.rootId;

    const slateValue = convertToSlateValue(data, includeRoot);

    return slateNodesToInsertDelta(slateValue);
  }

  public on(event: 'change', listener: (events: YDelta) => void): this;
  public on(event: 'update', listener: (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => void): this;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  public on(event: string, listener: (...args: any[]) => void): this {
    return super.on(event, listener);
  }

  public off(event: 'change', listener: (events: YDelta) => void): this;
  public off(event: 'update', listener: (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => void): this;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  public off(event: string, listener: (...args: any[]) => void): this {
    return super.off(event, listener);
  }

  public emit(event: 'change', events: YDelta): boolean;
  public emit(event: 'update', actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]): boolean;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  public emit(event: string, ...args: any[]): boolean {
    return super.emit(event, ...args);
  }

  private sendMessage = (docEvent: DocEventPB) => {
    // transform events to ops
    this.emit('change', DocEvent2YDelta(docEvent));
  };

  private handleReceiveMessage = (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => {
    this.queue.enqueue(actions);
  };

  private sendActions = async (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => {
    if (!actions.length) return;
    await applyActions(this.id, actions);
  };
}
