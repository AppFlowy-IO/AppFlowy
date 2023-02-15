import { FlowyError } from '../models/flowy-error';
import { SubscribeObject } from '../models/flowy-notification';

export declare type OnNotificationPayload<T> = (ty: T, payload: Uint8Array) => void;
export declare type OnNotificationError = (error: FlowyError) => void;
export declare type NotificationTyParser<T> = (num: number) => T | null;
export declare type ErrParser<E> = (data: Uint8Array) => E;

export abstract class NotificationParser<T> {
  id?: string;
  onPayload: OnNotificationPayload<T>;
  onError?: OnNotificationError;
  tyParser: NotificationTyParser<T>;

  constructor(
    onPayload: OnNotificationPayload<T>,
    tyParser: NotificationTyParser<T>,
    id?: string,
    onError?: OnNotificationError
  ) {
    this.id = id;
    this.onPayload = onPayload;
    this.onError = onError;
    this.tyParser = tyParser;
  }

  parse(subject: SubscribeObject) {
    if (typeof this.id !== 'undefined' && this.id.length === 0) {
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
      this.onError?.(error);
    } else {
      this.onPayload(ty, subject.payload);
    }
  }
}
