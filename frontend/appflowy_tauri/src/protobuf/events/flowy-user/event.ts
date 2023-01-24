
/// Auto generate. Do not edit
import { Ok, Err, Result } from "ts-results";
import { invoke } from "@tauri-apps/api/tauri";
import * as pb from "../../classes";

export async function UserEventInitUser(): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.InitUser],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        return Ok.EMPTY;
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventSignIn(payload: pb.SignInPayloadPB): Promise<Result<pb.UserProfilePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.SignIn],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.UserProfilePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventSignUp(payload: pb.SignUpPayloadPB): Promise<Result<pb.UserProfilePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.SignUp],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.UserProfilePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventSignOut(): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.SignOut],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        return Ok.EMPTY;
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventUpdateUserProfile(payload: pb.UpdateUserProfilePayloadPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.UpdateUserProfile],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        return Ok.EMPTY;
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventGetUserProfile(): Promise<Result<pb.UserProfilePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.GetUserProfile],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.UserProfilePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventCheckUser(): Promise<Result<pb.UserProfilePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.CheckUser],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.UserProfilePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventSetAppearanceSetting(payload: pb.AppearanceSettingsPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.SetAppearanceSetting],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        return Ok.EMPTY;
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventGetAppearanceSetting(): Promise<Result<pb.AppearanceSettingsPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.GetAppearanceSetting],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.AppearanceSettingsPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function UserEventGetUserSetting(): Promise<Result<pb.UserSettingPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.UserEvent[pb.UserEvent.GetUserSetting],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.UserSettingPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

