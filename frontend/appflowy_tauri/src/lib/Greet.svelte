<script>
  import { SignInPayloadPB } from "../protobuf/flowy-user/auth";
  import Event from "./Event.svelte";
  import {nanoid} from "nanoid";
  let userEvent;
</script>

<Event bind:this={userEvent} />

<button
  on:click={() =>
    userEvent.signIn(
      SignInPayloadPB.fromObject({
        email: nanoid(4) + "@gmail.com",
        password: "A!@123abc",
        name: "abc",
      })
    )}>Do Stuff</button
>
