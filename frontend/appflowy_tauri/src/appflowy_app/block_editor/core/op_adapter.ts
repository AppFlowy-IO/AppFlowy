import { BackendOp, LocalOp } from "$app/interfaces";

export class OpAdapter {

  toBackendOp(localOp: LocalOp): BackendOp {
    const backendOp: BackendOp = { ...localOp };
    // switch localOp type and generate backendOp
    return backendOp;
  }

  toLocalOp(backendOp: BackendOp): LocalOp {
    const localOp: LocalOp = { ...backendOp };
    // switch backendOp type and generate localOp
    return localOp;
  }
}
