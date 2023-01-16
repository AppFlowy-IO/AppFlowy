<script lang="ts">
    import { Ok, Err, Result } from "ts-results";
    import { invoke } from "@tauri-apps/api/tauri";
    import {SignInPayloadPB, UserEvent, UserProfilePB, FlowyError} from "../protobuf";

    export async function signIn(
        payload: SignInPayloadPB
    ): Promise<Result<UserProfilePB, FlowyError>> {
        let args = {
            request: {
                ty: UserEvent[UserEvent.SignIn],
                payload: Array.from(payload.serializeBinary()),
            },
        };
        let result: { code; payload } = await invoke("invoke_request", args);
        if (result.code == 0) {
            let userProfile = UserProfilePB.deserializeBinary(result.payload);
            console.log("Success:" + JSON.stringify(userProfile.toObject()))
            return Ok(userProfile);
        } else {
            let error = FlowyError.deserializeBinary(result.payload);
            console.log("Error:" + JSON.stringify(error.toObject()))
            return Err(error);
        }
    }
</script>
