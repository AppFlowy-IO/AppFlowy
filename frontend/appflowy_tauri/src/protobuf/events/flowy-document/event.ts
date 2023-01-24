
/// Auto generate. Do not edit
import { Ok, Err, Result } from "ts-results";
import { invoke } from "@tauri-apps/api/tauri";
import * as pb from "../../classes";

export async function DocumentEventGetDocument(payload: pb.OpenDocumentContextPB): Promise<Result<pb.DocumentSnapshotPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.DocumentEvent[pb.DocumentEvent.GetDocument],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.DocumentSnapshotPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

export async function DocumentEventApplyEdit(payload: pb.EditPayloadPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.DocumentEvent[pb.DocumentEvent.ApplyEdit],
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

export async function DocumentEventExportDocument(payload: pb.ExportPayloadPB): Promise<Result<pb.ExportDataPB, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.DocumentEvent[pb.DocumentEvent.ExportDocument],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        let object = pb.ExportDataPB.deserializeBinary(result.payload);
        console.log("Success:" + JSON.stringify(object.toObject()))
        return Ok(object);
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log("Error:" + JSON.stringify(error.toObject()))
        return Err(error);
    }
}

