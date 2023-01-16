<script lang="ts">
    import { Ok, Err, Result } from "ts-results";
    import type { SignInPayloadPB } from "../protobuf/flowy-user/auth";
    import { UserProfilePB } from "../protobuf/flowy-user/user_profile";
    import { FlowyError } from "../protobuf/flowy-error/errors";
    import { invoke } from "@tauri-apps/api/tauri";
    import { UserEvent } from "../protobuf/flowy-user/event_map";

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
