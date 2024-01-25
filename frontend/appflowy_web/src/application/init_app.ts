import { initEventBus } from "./event_bus.ts";
import { register_listener } from "../../wasm-libs/af-wasm/pkg";

export function initApp() {
  initEventBus();
  register_listener();
}
