import { ViewLayoutPB, WorkspaceSettingPB } from '@/services/backend';
import { FolderEventGetCurrentWorkspace } from '@/services/backend/events/flowy-folder2';
import { AppBackendService } from '$app/stores/effects/folder/app/app_bd_svc';

export async function createTestDocument() {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventGetCurrentWorkspace().then((result) => result.unwrap());
  const app = workspaceSetting.workspace.views[0];
  const appService = new AppBackendService(app.id);
  return await appService.createView({ name: 'New Document', layoutType: ViewLayoutPB.Document });
}
