import { ViewLayoutTypePB, WorkspaceSettingPB } from '../../../services/backend';
import { FolderEventReadCurrentWorkspace } from '../../../services/backend/events/flowy-folder';
import { AppBackendService } from '../../stores/effects/folder/app/app_bd_svc';

export async function createTestDocument() {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventReadCurrentWorkspace().then((result) => result.unwrap());
  const app = workspaceSetting.workspace.apps.items[0];
  const appService = new AppBackendService(app.id);
  return await appService.createView({ name: 'New Document', layoutType: ViewLayoutTypePB.Document });
}
