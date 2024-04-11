import { EventEmitter } from "events";
import { NotifyArgs } from "../@types/global";

const AF_NOTIFICATION = "af-notification";

let eventEmitter: EventEmitter;
export function getEventEmitterInstance() {
  if (!eventEmitter) {
    eventEmitter = new EventEmitter();
  }
  return eventEmitter;
}

export function initEventBus() {
  window.onFlowyNotify = (eventName: string, args: NotifyArgs) => {
    notify(eventName, args);
  };
}

export function notify(_eventName: string, args: NotifyArgs) {
  const eventEmitter = getEventEmitterInstance();
  eventEmitter.emit(AF_NOTIFICATION, args);
}

export function onNotify(callback: (args: NotifyArgs) => void) {
  const eventEmitter = getEventEmitterInstance();
  eventEmitter.on(AF_NOTIFICATION, callback);
  return offNotify;
}

export function offNotify() {
  const eventEmitter = getEventEmitterInstance();
  eventEmitter.removeAllListeners(AF_NOTIFICATION);
}
