import { initEventBus } from "./event_bus.ts";
import { register_listener } from "../../appflowy-wasm/pkg";

export function initApp() {
  initEventBus();
  register_listener();
}
