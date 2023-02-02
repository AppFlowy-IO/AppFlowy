import "./App.css";
import {
  UserEventSignIn,
  SignInPayloadPB,
} from "../services/backend/events/flowy-user/index";
import { nanoid } from "nanoid";
import { UserNotificationListener } from "./components/user/application/notifications";


function App() {
  async function sendSignInEvent() {
    let make_payload = () =>
      SignInPayloadPB.fromObject({
        email: nanoid(4) + "@gmail.com",
        password: "A!@123abc",
        name: "abc",
      });

      let listener = await new UserNotificationListener({
        onUserSignIn: (userProfile) => {
        console.log(userProfile);
      }, onProfileUpdate(userProfile) {
        console.log(userProfile);
        // stop listening the changes
        listener.stop();
      }});

      listener.start();

    await UserEventSignIn(make_payload());
  }

  return (
    <div className="container">
      <h1>Welcome to AppFlowy!</h1>
      <button type="button" onClick={() => sendSignInEvent()}>
       Test Sign In Event 
      </button>
    </div>
  );
}

export default App;
