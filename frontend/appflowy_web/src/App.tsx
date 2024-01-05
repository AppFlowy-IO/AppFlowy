import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";
import { invoke_request } from "../appflowy-wasm/pkg/appflowy_wasm";
import { useEffect } from "react";
import { initApp } from "./application/init_app.ts";
import { subscribeNotification } from "./application/notification.ts";
import { NotifyArgs } from "./@types/global";

function App() {
  useEffect(() => {
    initApp();
    return subscribeNotification((event: NotifyArgs) => {
      console.log(event);
    });
  }, []);

  const handleClick = async () => {
    const payload = new TextEncoder().encode("someString");
    const res = await invoke_request("add", payload);
    console.log(res);
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
