
/// Auto generate. Do not edit
import { Ok, Err, Result } from "ts-results";
import { invoke } from "@tauri-apps/api/tauri";
import * as pb from "../../classes";

export async function NetworkEventUpdateNetworkType(payload: pb.NetworkState): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.NetworkEvent[pb.NetworkEvent.UpdateNetworkType],
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

