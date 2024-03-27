export interface UserProfilePB {
  id: string;
  name: string;
  email: string;
  user_metadata: {
    avatar_url: string;
    full_name: string;
  };
}

export interface WorkspacePB {
  workspace_id: string;
  database_storage_id: string;
  owner_uid: number;
  owner_name: string;
  workspace_type: number;
  workspace_name: string;
  created_at: string;
  icon: string;
}

export enum EncoderVersion {
  V1 = 0,
  V2 = 1,
}

export enum CollabType {
  Document = 0,
  Database = 1,
  WorkspaceDatabase = 2,
  Folder = 3,
  DatabaseRow = 4,
  UserAwareness = 5,
}

export interface EncodedCollab {
  state_vector: Uint8Array;
  doc_state: Uint8Array;
  version: EncoderVersion;
}
