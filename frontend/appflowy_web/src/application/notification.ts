import { NotifyArgs } from "../@types/global";
import { onNotify } from "./event_bus.ts";

export function subscribeNotification(
  callback: (args: NotifyArgs) => void,
  options?: { id?: string }
) {
  return onNotify((payload) => {
    const { id } = payload;

    if (options?.id !== undefined && id !== options.id) {
      return;
    }

    callback(payload);
  });
}
