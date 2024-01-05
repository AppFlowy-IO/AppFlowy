import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'


import {init_sdk, async_event, init_tracing} from '../../pkg/flowy_wasm';
async function runWasm() {
    init_tracing();
    init_sdk("sdk config"); // Call your exported Wasm function.
}
runWasm();



function App() {
  const [count ] = useState(0)
    const handleClick = async () => {
        async_event("hello", new Uint8Array([1, 2, 3, 4]));
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
        <button onClick={handleClick}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App

