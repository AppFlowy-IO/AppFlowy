import { listen, UnlistenFn } from '@tauri-apps/api/event';
import { SubscribeObject } from '../models/flowy-notification';
import { NotificationParser } from './parser';

export abstract class AFNotificationObserver<T> {
  parser?: NotificationParser<T> | null;
  private _listener?: UnlistenFn;

  protected constructor(parser?: NotificationParser<T>) {
    this.parser = parser;
  }

  async start() {
    this._listener = await listen('af-notification', (notification) => {
      const object = SubscribeObject.fromObject(notification.payload as {});
      this.parser?.parse(object);
    });
  }

  async stop() {
    if (this._listener !== undefined) {
      this._listener = undefined;
    }
    this.parser = null;
  }
}
