import {
  DuplicatePublishView,
  FolderView,
  Invitation,
  User,
  UserWorkspaceInfo,
  Workspace,
  YDoc,
  View, DatabaseRelations,
} from '@/application/types';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { AFService } from '@/application/services/services.type';
import {
  Template, TemplateCategory,
  TemplateCategoryFormValues, TemplateCreator,
  TemplateCreatorFormValues, TemplateSummary,
  UploadTemplatePayload,
} from '@/application/template.type';
import { nanoid } from 'nanoid';
import { YMap } from 'yjs/dist/src/types/YMap';

export class AFClientService implements AFService {
  private deviceId: string = nanoid(8);

  private clientId: string = 'tauri';

  async getPublishView (_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishInfo (_viewId: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishOutline (_namespace: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishViewMeta (_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  getClientId (): string {
    return '';
  }

  loginAuth (_: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInDiscord (_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInGithub (_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInGoogle (_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInApple (_params: { redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  signInMagicLink (_params: { email: string; redirectTo: string }): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getPublishDatabaseViewRows (
    _namespace: string,
    _publishName: string,
  ): Promise<{
    rows: YMap<YDoc>;
    destroy: () => void;
  }> {
    return Promise.reject('Method not implemented');
  }

  duplicatePublishView (_params: DuplicatePublishView): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getCurrentUser (): Promise<User> {
    return Promise.reject('Method not implemented');
  }

  getWorkspaceFolder (_workspaceId: string): Promise<FolderView> {
    return Promise.reject('Method not implemented');
  }

  getWorkspaces (): Promise<Workspace[]> {
    return Promise.reject('Method not implemented');
  }

  addPublishViewReaction (_viewId: string, _commentId: string, _reactionType: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  createCommentOnPublishView (_viewId: string, _content: string, _replyCommentId: string | undefined): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  deleteCommentOnPublishView (_viewId: string, _commentId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getPublishViewGlobalComments (_viewId: string): Promise<GlobalComment[]> {
    return Promise.resolve([]);
  }

  getPublishViewReactions (_viewId: string, _commentId: string | undefined): Promise<Record<string, Reaction[]>> {
    return Promise.reject('Method not implemented');
  }

  removePublishViewReaction (_viewId: string, _commentId: string, _reactionType: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  addTemplateCategory (_category: TemplateCategoryFormValues): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  createTemplate (_template: UploadTemplatePayload): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  createTemplateCreator (_creator: TemplateCreatorFormValues): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  deleteTemplate (_id: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  deleteTemplateCategory (_categoryId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  deleteTemplateCreator (_creatorId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getTemplateById (_id: string): Promise<Template> {
    return Promise.reject('Method not implemented');
  }

  getTemplateCategories (): Promise<TemplateCategory[]> {
    return Promise.resolve([]);
  }

  getTemplateCreators (): Promise<TemplateCreator[]> {
    return Promise.resolve([]);
  }

  getTemplates (_params: { categoryId?: string; nameContains?: string }): Promise<TemplateSummary[]> {
    return Promise.resolve([]);
  }

  updateTemplate (_id: string, _template: UploadTemplatePayload): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  updateTemplateCategory (_categoryId: string, _category: TemplateCategoryFormValues): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  updateTemplateCreator (_creatorId: string, _creator: TemplateCreatorFormValues): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  uploadFileToCDN (_file: File): Promise<string> {
    return Promise.resolve('');
  }

  acceptInvitation (_invitationId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getInvitation (_invitationId: string): Promise<Invitation> {
    return Promise.reject('Method not implemented');
  }

  getAppOutline (_workspaceId: string): Promise<View[]> {
    return Promise.reject('Method not implemented');
  }

  getDatabasePageRows (_workspaceId: string, _viewId: string): Promise<{ rows: YMap<YDoc>; destroy: () => void }> {
    return Promise.reject('Method not implemented');
  }

  getPageDoc (_workspaceId: string, _viewId: string): Promise<YDoc> {
    return Promise.reject('Method not implemented');
  }

  getUserWorkspaceInfo (): Promise<UserWorkspaceInfo> {
    return Promise.reject('Method not implemented');
  }

  getAppDatabaseViewRelations (_workspaceId: string, _databaseStorageId: string): Promise<DatabaseRelations> {
    return Promise.reject('Method not implemented');
  }

  openWorkspace (_workspaceId: string): Promise<void> {
    return Promise.reject('Method not implemented');
  }

  getAppFavorites (_workspaceId: string): Promise<View[]> {
    return Promise.reject('Method not implemented');
  }

  getAppRecent (_workspaceId: string): Promise<View[]> {
    return Promise.reject('Method not implemented');
  }

  getAppTrash (_workspaceId: string): Promise<View[]> {
    return Promise.reject('Method not implemented');
  }

  getAppView (_workspaceId: string, _viewId: string): Promise<View> {
    return Promise.reject('Method not implemented');
  }

  createRowDoc (_rowKey: string): Promise<YDoc> {
    return Promise.reject('Method not implemented');
  }

  deleteRowDoc (_rowKey: string): void {
    return;
  }

  getPublishRowDocument (_viewId: string): Promise<YDoc> {
    return Promise.reject('Method not implemented');
  }

}
