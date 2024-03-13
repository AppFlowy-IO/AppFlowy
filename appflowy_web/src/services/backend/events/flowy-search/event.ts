
/// Auto generate. Do not edit
import { Ok, Err, Result } from "ts-results";
import { invoke } from "@/application/app.ts";
import * as pb from "../..";

export async function SearchEventSearch(payload: pb.SearchQueryPB): Promise<Result<void, pb.FlowyError>> {
    let args = {
        request: {
            ty: pb.SearchEvent[pb.SearchEvent.Search],
            payload: Array.from(payload.serializeBinary()),
        },
    };

    let result: { code: number; payload: Uint8Array } = await invoke("invoke_request", args);
    if (result.code == 0) {
        return Ok.EMPTY;
    } else {
        let error = pb.FlowyError.deserializeBinary(result.payload);
        console.log(SearchEventSearch.name, error);
        return Err(error);
    }
}

