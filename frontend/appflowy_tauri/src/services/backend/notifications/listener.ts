import { listen, UnlistenFn } from "@tauri-apps/api/event";
import { FlowyError } from "../models/flowy-error";
import { SubscribeObject } from "../models/flowy-notification";
import { NotificationParser } from "./parser";

declare type OnError = (error: FlowyError) => void;

export abstract class AFNotificationListener<T> {
  parser?: NotificationParser<T> | null;
  private _listener?: UnlistenFn;

  protected constructor(parser?: NotificationParser<T>) {
    this.parser = parser;
  }

  async start() {
    this._listener = await listen("af-notification", (notification) => {
      let object = SubscribeObject.fromObject(notification.payload as {});
      this.parser?.parse(object);
    });
  }

  async stop() {
    if (this._listener != null) {
      this._listener();
    }
    this.parser = null;
  }
}
