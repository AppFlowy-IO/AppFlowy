import "./App.css";
import {
  UserEventSignIn,
  SignInPayloadPB,
} from "../services/backend/events/flowy-user";
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
    <div className="text-white bg-gray-500 h-screen flex flex-col justify-center items-center gap-4">
      <h1 className="text-3xl">Welcome to AppFlowy!</h1>

      <div>
        <button
          className="bg-gray-700 p-4 rounded-md"
          type="button"
          onClick={() => greet()}
        >
          Sign in
        </button>
      </div>
    </div>
  );
}

export default App;
