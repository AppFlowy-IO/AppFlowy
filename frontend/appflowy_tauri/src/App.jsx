import { useState } from "react";
import reactLogo from "./assets/react.svg";
import { invoke } from "@tauri-apps/api/tauri";
import { emit, listen } from "@tauri-apps/api/event";
import { Button } from 'antd';

import "./App.css";

const AF_EVENT = "af-event";
const AF_NOTIFICATION= "af-notification";
async function emit_af_event(payload) {
    // listen(AF_NOTIFICATION, (event) => {
    //     // event.event is the event name (useful if you want to use a single callback fn for multiple event types)
    //     // event.payload is the payload object
    //     console.log(event);
    // });
    emit(AF_EVENT, payload)
}


function App() {
    const [greetMsg, setGreetMsg] = useState("");
    const [name, setName] = useState("");

    async function greet() {
        await emit_af_event({
            theMessage: 'Message from the frontend!',
        })
        // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
        setGreetMsg(await invoke("greet", { name }));
    }


    return (
        <div className="container">
            <h1>Welcome to Tauri!</h1>

            <div className="row">
                <a href="https://vitejs.dev" target="_blank">
                    <img src="/vite.svg" className="logo vite" alt="Vite logo" />
                </a>
                <a href="https://tauri.app" target="_blank">
                    <img src="/tauri.svg" className="logo tauri" alt="Tauri logo" />
                </a>
                <a href="https://reactjs.org" target="_blank">
                    <img src={reactLogo} className="logo react" alt="React logo" />
                </a>
            </div>

            <p>Click on the Tauri, Vite, and React logos to learn more.</p>

            <div className="row">
                <div>
                    <input
                        id="greet-input"
                        onChange={(e) => setName(e.currentTarget.value)}
                        placeholder="Enter a name..."
                    />
                    <button type="button" onClick={() => greet()}>
                        Greet
                    </button>
                </div>
            </div>
            <Button className="123" type="primary" onClick={() => greet()}>Button</Button>

            <p>{greetMsg}</p>
        </div>
    );
}

export default App;
