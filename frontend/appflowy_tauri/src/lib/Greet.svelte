<script lang="ts">
  import { invoke } from "@tauri-apps/api/tauri"
  import {UserEvent} from "../protobuf/flowy-user/event_map";

  let name = "";
  let greetMsg = ""

  async function greet(){
    // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command

    let args = {
      request: {
        ty: UserEvent.InitUser.toString(),
        payload: 'hello'
      }
    };
    let response = await invoke("invoke_request",  args );
    console.log(response);
  }
</script>

<div>
  <div class="row">
    <input id="greet-input" placeholder="Enter a name..." bind:value={name} />
    <button on:click={greet}>
      Greet
    </button>
  </div>
  <p>{greetMsg}</p>
</div>