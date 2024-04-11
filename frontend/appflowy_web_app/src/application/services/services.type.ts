import { YDoc } from '@/application/document.type';
import { ProviderType, SignUpWithEmailPasswordParams, UserProfile } from '@/application/user.type';

export interface AFService {
  getDeviceID: () => string;
  getClientID: () => string;
  authService: AuthService;
  userService: UserService;
  documentService: DocumentService;
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
  openDocument: (workspaceId: string, docId: string) => Promise<YDoc>;
}

export interface UserService {
  getUserProfile: () => Promise<UserProfile | null>;
}
