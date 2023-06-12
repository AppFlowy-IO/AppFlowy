import { ViewLayoutPB, WorkspaceSettingPB } from '@/services/backend';
import { FolderEventGetCurrentWorkspace } from '@/services/backend/events/flowy-folder2';
import {WorkspaceBackendService} from "$app/stores/effects/folder/workspace/workspace_bd_svc";

export async function createTestDocument() {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventGetCurrentWorkspace().then((result) => result.unwrap());
  const appService = new WorkspaceBackendService(workspaceSetting.workspace.id);
  return await appService.createView({ name: 'New Document', layoutType: ViewLayoutPB.Document });
}
