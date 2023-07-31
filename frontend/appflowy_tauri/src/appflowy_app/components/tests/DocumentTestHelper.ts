import { ViewLayoutPB, WorkspaceSettingPB } from '@/services/backend';
import { FolderEventGetCurrentWorkspace } from '@/services/backend/events/flowy-folder2';
import { WorkspaceController } from '../../stores/effects/workspace/workspace_controller';

export async function createTestDocument() {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventGetCurrentWorkspace().then((result) => result.unwrap());
  const appService = new WorkspaceController(workspaceSetting.workspace.id);
  const result = await appService.createView({ name: 'New Document', layout: ViewLayoutPB.Document });

  return result;
}
