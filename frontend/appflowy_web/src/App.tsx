import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";
import { useEffect } from "react";
import {initApp,  invoke} from "./application/app.ts";
import { subscribeNotification } from "./application/notification.ts";
import { NotifyArgs } from "./@types/global";
import {init_tracing_log, init_wasm_core} from "../wasm-libs/af-wasm/pkg";

init_tracing_log();
// FIXME: handle the promise that init_wasm_core returns
init_wasm_core();

function App() {
  useEffect(() => {
    initApp();
    return subscribeNotification((event: NotifyArgs) => {
      console.log(event);
    });
  }, []);

  const handleClick = async () => {
      let args = {
          request: {
              ty: "test",
              payload: new TextEncoder().encode("someString"),
          },
      };
      invoke("invoke_request", args);
  };

  return (
    <>
      <div>
        <a href="https://vitejs.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={handleClick}>Click me!</button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  );
}

export default App;
