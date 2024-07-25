import { CollabType } from '@/application/collab.type';

export interface Workspace {
  icon: string;
  id: string;
  name: string;
  memberCount: number;
}

export interface SpaceView {
  id: string;
  extra: string | null;
  name: string;
  isPrivate: boolean;
}

export interface FolderView {
  id: string;
  icon: string | null;
  extra: string | null;
  name: string;
  isSpace: boolean;
  isPrivate: boolean;
  children: FolderView[];
}

export interface User {
  email: string | null;
  name: string | null;
  uid: string;
  avatar: string | null;
}

export interface DuplicatePublishView {
  workspaceId: string;
  spaceViewId: string;
  collabType: CollabType;
  viewId: string;
}
