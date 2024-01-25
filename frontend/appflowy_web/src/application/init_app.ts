import { initEventBus } from "./event_bus.ts";
import { register_listener } from "../../wasm-libs/appflowy-wasm/pkg";

export function initApp() {
  initEventBus();
  register_listener();
}
