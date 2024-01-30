import { FlowyError } from "../models/flowy-error";
import { SubscribeObject } from "../models/flowy-notification";
import { Err, Ok, Result } from "ts-results";

export declare type OnNotificationPayload<T> = (ty: T, payload: Result<Uint8Array, FlowyError>) => void;
export declare type OnNotificationError = (error: FlowyError) => void;
export declare type NotificationTyParser<T> = (num: number) => T | null;
export declare type ErrParser<E> = (data: Uint8Array) => E;

export abstract class NotificationParser<T> {
  id?: string;
  onPayload: OnNotificationPayload<T>;
  tyParser: NotificationTyParser<T>;

  protected constructor(
    onPayload: OnNotificationPayload<T>,
    tyParser: NotificationTyParser<T>,
    id?: string
  ) {
    this.id = id;
    this.onPayload = onPayload;
    this.tyParser = tyParser;
  }

  parse(subject: SubscribeObject) {
    if (typeof this.id !== "undefined" && this.id.length === 0) {
      if (subject.id !== this.id) {
        return;
      }
    }

    const ty = this.tyParser(subject.ty);
    if (ty === null) {
      return;
    }

    if (subject.has_error) {
      const error = FlowyError.deserializeBinary(subject.error);
      this.onPayload(ty, Err(error));
    } else {
      this.onPayload(ty, Ok(subject.payload));
    }
  }
}
