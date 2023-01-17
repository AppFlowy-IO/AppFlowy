<script>
  import { nanoid } from "nanoid";
  import {
    UserEventSignIn,
    SignInPayloadPB,
  } from "../protobuf/events/flowy-user";
  let userEvent;

  let make_payload = () =>
    SignInPayloadPB.fromObject({
      email: nanoid(4) + "@gmail.com",
      password: "A!@123abc",
      name: "abc",
    });
</script>

<button on:click={() => UserEventSignIn(make_payload())}>Sign In</button>
