import { ViewLayoutPB, WorkspaceSettingPB } from '@/services/backend';
import { WorkspaceController } from '../../stores/effects/workspace/workspace_controller';
import { FolderEventGetCurrentWorkspaceSetting } from '@/services/backend/events/flowy-folder2';

export async function createTestDocument() {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventGetCurrentWorkspaceSetting().then((result) =>
    result.unwrap()
  );
  const appService = new WorkspaceController(workspaceSetting.workspace_id);
  const result = await appService.createView({ name: 'New Document', layout: ViewLayoutPB.Document });

  return result;
}
