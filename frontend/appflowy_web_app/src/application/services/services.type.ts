import { ProviderType, SignUpWithEmailPasswordParams, UserProfile } from '@/application/services/user.type';

export interface AFService {
  getDeviceID: () => string;
  getClientID: () => string;
  authService: AuthService;
  userService: UserService;
  documentService: DocumentService;
  load: () => Promise<void>;
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
  signInWithOAuth: (params: { uri: string }) => Promise<UserProfile>;
  signupWithEmailPassword: (params: SignUpWithEmailPasswordParams) => Promise<UserProfile>;
  signinWithEmailPassword: (email: string, password: string) => Promise<UserProfile>;
  signOut: () => Promise<void>;
}

export interface DocumentService {
  openDocument: (docID: string) => Promise<void>;
}

export interface UserService {
  getUserProfile: () => Promise<UserProfile | null>;
}
