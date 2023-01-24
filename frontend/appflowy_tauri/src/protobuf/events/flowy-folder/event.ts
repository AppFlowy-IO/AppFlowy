
/// Auto generate. Do not edit
import { Ok, Err, Result } from "ts-results";
import { invoke } from "@tauri-apps/api/tauri";
import * as pb from "../../classes";

export async function FolderEventCreateWorkspace(payload: pb.CreateWorkspacePayloadPB): Promise<Result<pb.WorkspacePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.CreateWorkspace],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.WorkspacePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventReadCurrentWorkspace(): Promise<Result<pb.WorkspaceSettingPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadCurrentWorkspace],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.WorkspaceSettingPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventReadWorkspaces(payload: pb.WorkspaceIdPB): Promise<Result<pb.RepeatedWorkspacePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadWorkspaces],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.RepeatedWorkspacePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventDeleteWorkspace(payload: pb.WorkspaceIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DeleteWorkspace],
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

export async function FolderEventOpenWorkspace(payload: pb.WorkspaceIdPB): Promise<Result<pb.WorkspacePB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.OpenWorkspace],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.WorkspacePB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventReadWorkspaceApps(payload: pb.WorkspaceIdPB): Promise<Result<pb.RepeatedAppPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadWorkspaceApps],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.RepeatedAppPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventCreateApp(payload: pb.CreateAppPayloadPB): Promise<Result<pb.AppPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.CreateApp],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.AppPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventDeleteApp(payload: pb.AppIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DeleteApp],
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

export async function FolderEventReadApp(payload: pb.AppIdPB): Promise<Result<pb.AppPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadApp],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.AppPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventUpdateApp(payload: pb.UpdateAppPayloadPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.UpdateApp],
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

export async function FolderEventCreateView(payload: pb.CreateViewPayloadPB): Promise<Result<pb.ViewPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.CreateView],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.ViewPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventReadView(payload: pb.ViewIdPB): Promise<Result<pb.ViewPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadView],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.ViewPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventUpdateView(payload: pb.UpdateViewPayloadPB): Promise<Result<pb.ViewPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.UpdateView],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.ViewPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventDeleteView(payload: pb.RepeatedViewIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DeleteView],
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

export async function FolderEventDuplicateView(payload: pb.ViewPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DuplicateView],
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

export async function FolderEventCloseView(payload: pb.ViewIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.CloseView],
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

export async function FolderEventReadViewInfo(payload: pb.ViewIdPB): Promise<Result<pb.ViewInfoPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadViewInfo],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.ViewInfoPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventCopyLink(): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.CopyLink],
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

export async function FolderEventSetLatestView(payload: pb.ViewIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.SetLatestView],
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

export async function FolderEventMoveFolderItem(payload: pb.MoveFolderItemPayloadPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.MoveFolderItem],
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

export async function FolderEventReadTrash(): Promise<Result<pb.RepeatedTrashPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.ReadTrash],
            payload: Array.from([]),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.RepeatedTrashPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function FolderEventPutbackTrash(payload: pb.TrashIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.PutbackTrash],
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

export async function FolderEventDeleteTrash(payload: pb.RepeatedTrashIdPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DeleteTrash],
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

export async function FolderEventRestoreAllTrash(): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.RestoreAllTrash],
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

export async function FolderEventDeleteAllTrash(): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.FolderEvent[pb.FolderEvent.DeleteAllTrash],
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

