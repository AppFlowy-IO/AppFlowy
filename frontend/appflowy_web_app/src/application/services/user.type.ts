export enum Authenticator {
  Local = 0,
  Supabase = 1,
  AppFlowyCloud = 2,
}

export enum EncryptionType {
  NoEncryption = 0,
  Symmetric = 1,
}

export interface UserProfile {
  id?: string;
  email?: string;
  name?: string;
  token?: string;
  iconUrl?: string;
  openaiKey?: string;
  authenticator?: Authenticator;
  encryptionSign?: string;
  encryptionType?: EncryptionType;
  workspaceId?: string;
  stabilityAiKey?: string;
}

export interface Workspace {
  id: string;
  name: string;
  icon: string;
  owner: {
    id: number;
    name: string;
  };
}

export interface SignUpWithEmailPasswordParams {
  name: string;
  email: string;
  password: string;
}

export enum ProviderType {
  Apple = 0,
  Azure = 1,
  Bitbucket = 2,
  Discord = 3,
  Facebook = 4,
  Figma = 5,
  Github = 6,
  Gitlab = 7,
  Google = 8,
  Keycloak = 9,
  Kakao = 10,
  Linkedin = 11,
  Notion = 12,
  Spotify = 13,
  Slack = 14,
  Workos = 15,
  Twitch = 16,
  Twitter = 17,
  Email = 18,
  Phone = 19,
  Zoom = 20,
}

export interface UserSetting {
  workspaceId: string;
  latestView?: {
    id: string;
    name: string;
  };
  hasLatestView: boolean;
}
