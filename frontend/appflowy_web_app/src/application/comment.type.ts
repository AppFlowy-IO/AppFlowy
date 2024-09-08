export interface CommentUser {
  uuid: string;
  name: string;
  avatarUrl: string | null;
}

export interface GlobalComment {
  commentId: string;
  user: CommentUser | null;
  content: string;
  createdAt: string;
  lastUpdatedAt: string;
  replyCommentId: string | null;
  isDeleted: boolean;
  canDeleted: boolean;
}

export interface Reaction {
  reactionType: string;
  reactUsers: CommentUser[];
  commentId: string;
}
