import { YDoc } from '@/application/collab.type';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { AFService } from '@/application/services/services.type';
import { nanoid } from 'nanoid';
import { YMap } from 'yjs/dist/src/types/YMap';
import { DuplicatePublishView, FolderView, User, Workspace } from '@/application/types';

export class AFClientService implements AFService {
  private deviceId: string = nanoid(8);

  private clientId: string = 'tauri';

  async getPublishView(_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishInfo(_viewId: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishViewMeta(_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  getClientId(): string {
    return '';
  }

  loginAuth(_: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInDiscord(_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInGithub(_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInGoogle(_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInMagicLink(_params: { email: string; redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getPublishDatabaseViewRows(
    _namespace: string,
    _publishName: string
  ): Promise<{
    rows: YMap<YDoc>;
    destroy: () => void;
  }> {
    return Promise.reject('Method not implemented');
  }

  duplicatePublishView(_params: DuplicatePublishView): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getCurrentUser(): Promise<User> {
    return Promise.reject('Method not implemented');
  }

  getWorkspaceFolder(_workspaceId: string): Promise<FolderView> {
    return Promise.reject('Method not implemented');
  }

  getWorkspaces(): Promise<Workspace[]> {
    return Promise.reject('Method not implemented');
  }

  addPublishViewReaction(_viewId: string, _commentId: string, _reactionType: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  createCommentOnPublishView(_viewId: string, _content: string, _replyCommentId: string | undefined): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  deleteCommentOnPublishView(_viewId: string, _commentId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getPublishViewGlobalComments(_viewId: string): Promise<GlobalComment[]> {
    return Promise.resolve([]);
  }

  getPublishViewReactions(_viewId: string, _commentId: string | undefined): Promise<Record<string, Reaction[]>> {
    return Promise.reject('Method not implemented');
  }

  removePublishViewReaction(_viewId: string, _commentId: string, _reactionType: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }
}
