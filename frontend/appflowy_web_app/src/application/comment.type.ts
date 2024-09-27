import { AFWebUser } from '@/application/types';

export interface GlobalComment {
  commentId: string;
  user: AFWebUser | null;
  content: string;
  createdAt: string;
  lastUpdatedAt: string;
  replyCommentId: string | null;
  isDeleted: boolean;
  canDeleted: boolean;
}

export interface Reaction {
  reactionType: string;
  reactUsers: AFWebUser[];
  commentId: string;
}
