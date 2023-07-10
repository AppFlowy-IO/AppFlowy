import { listen, UnlistenFn } from "@tauri-apps/api/event";
import { SubscribeObject } from "../models/flowy-notification";
import { NotificationParser } from "./parser";

export abstract class AFNotificationObserver<T> {
  parser?: NotificationParser<T> | null;
  private _listener?: UnlistenFn;

  protected constructor(parser?: NotificationParser<T>) {
    this.parser = parser;
  }

  async start() {
    this._listener = await listen("af-notification", (notification) => {
      const object: SubscribeObject = SubscribeObject.fromObject(notification.payload as {});
      if (this.parser?.id !== undefined) {
        if (object.id === this.parser.id) {
          this.parser?.parse(object);
        }
      } else {
        this.parser?.parse(object);
      }
    });
  }

  async stop() {
    if (this._listener !== undefined) {
      // call the unlisten function before setting it to undefined
      this._listener();
      this._listener = undefined;
    }
    this.parser = null;
  }
}
