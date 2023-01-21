import "./App.css";
import {
  UserEventSignIn,
  SignInPayloadPB,
} from "../services/protobuf/events/flowy-user";
import { nanoid } from "nanoid";


function App() {
  async function greet() {
    let make_payload = () =>
      SignInPayloadPB.fromObject({
        email: nanoid(4) + "@gmail.com",
        password: "A!@123abc",
        name: "abc",
      });
    await UserEventSignIn(make_payload());
  }

  return (
    <div className="container">
      <h1>Welcome to AppFlowy!</h1>

      <button type="button" onClick={() => greet()}>
        Sign in
      </button>
    </div>
  );
}

export default App;
