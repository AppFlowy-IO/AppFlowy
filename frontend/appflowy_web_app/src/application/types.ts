import { CollabType, ViewLayout } from '@/application/collab.type';

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
  uuid: string;
}

export interface DuplicatePublishView {
  workspaceId: string;
  spaceViewId: string;
  collabType: CollabType;
  viewId: string;
}

export enum ViewIconType {
  Emoji = 0,
  Icon = 1,
}

export interface ViewIcon {
  ty: ViewIconType;
  value: string;
}

export interface ViewExtra {
  is_space: boolean;
  space_created_at?: number;
  space_icon?: string;
  space_icon_color?: string;
  space_permission?: number;
}

export interface View {
  view_id: string;
  name: string;
  icon: ViewIcon | null;
  layout: ViewLayout;
  extra: ViewExtra | null;
  children: View[];
  is_published: boolean;
}

export interface Invitation {
  invite_id: string;
  workspace_id: string;
  workspace_name: string;
  inviter_email: string;
  inviter_name: string;
  inviter_icon: string;
  workspace_icon: string;
  member_count: number;
  status: 'Accepted' | 'Pending';
}