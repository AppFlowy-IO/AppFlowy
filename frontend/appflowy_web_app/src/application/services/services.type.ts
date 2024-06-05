import { YDoc } from '@/application/collab.type';
import { ProviderType, SignUpWithEmailPasswordParams, UserProfile } from '@/application/user.type';
import * as Y from 'yjs';

export interface AFService {
  getDeviceID: () => string;
  getClientID: () => string;
  authService: AuthService;
  userService: UserService;
  documentService: DocumentService;
  folderService: FolderService;
  databaseService: DatabaseService;
}

export interface AFServiceConfig {
  cloudConfig: AFCloudConfig;
}

export interface AFCloudConfig {
  baseURL: string;
  gotrueURL: string;
  wsURL: string;
}

export interface AuthService {
  getOAuthURL: (provider: ProviderType) => Promise<string>;
  signInWithOAuth: (params: { uri: string }) => Promise<void>;
  signupWithEmailPassword: (params: SignUpWithEmailPasswordParams) => Promise<void>;
  signinWithEmailPassword: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

export interface DocumentService {
  openDocument: (docId: string) => Promise<YDoc>;
}

export interface DatabaseService {
  getWorkspaceDatabases: () => Promise<{ views: string[]; database_id: string }[]>;
  openDatabase: (
    databaseId: string,
    rowIds?: string[]
  ) => Promise<{
    databaseDoc: YDoc;
    rows: Y.Map<YDoc>;
  }>;
  closeDatabase: (databaseId: string) => Promise<void>;
}

export interface UserService {
  getUserProfile: () => Promise<UserProfile | null>;
  checkUser: () => Promise<boolean>;
}

export interface FolderService {
  openWorkspace: (workspaceId: string) => Promise<YDoc>;
}
