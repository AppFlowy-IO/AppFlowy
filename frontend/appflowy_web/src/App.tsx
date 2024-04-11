import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";
import { useEffect } from "react";
import { initApp } from "@/application/app.ts";
import { subscribeNotification } from "@/application/notification.ts";
import { NotifyArgs } from "./@types/global";
import { init_tracing_log, init_wasm_core } from "../wasm-libs/af-wasm/pkg";
import { v4 as uuidv4 } from 'uuid';
import {AddUserPB, UserWasmEventAddUser} from "@/services/backend/events/user";

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
    let email = `${uuidv4()}@example.com`;
    let password = "AppFlowy!2024";
    const payload = AddUserPB.fromObject({email: email, password: password })
    let result = await UserWasmEventAddUser(payload);
    if (!result.ok) {

    }
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
