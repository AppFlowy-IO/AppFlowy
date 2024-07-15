import { EventEmitter } from 'events';

const event = new EventEmitter();

export enum EventType {
  SESSION_EXPIRED = 'session_expired',
  SESSION_REFRESH = 'session_refresh',
  SESSION_INVALID = 'session_invalid',
  SESSION_VALID = 'session_valid',
}

export type Listener<T> = (data: T) => void;

export function on<T>(eventType: EventType, listener: Listener<T>) {
  event.on(eventType, listener);

  return () => {
    event.off(eventType, listener);
  };
}

export function emit<T>(eventType: EventType, data?: T) {
  event.emit(eventType, data);
}
