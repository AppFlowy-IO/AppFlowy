import { parserViewPBToPage } from '$app_reducers/pages/slice';
import {
  ChangeWorkspaceIconPB,
  CreateViewPayloadPB,
  GetWorkspaceViewPB,
  RenameWorkspacePB,
  UserWorkspaceIdPB,
  WorkspaceIdPB,
} from '@/services/backend';
import {
  FolderEventCreateView,
  FolderEventDeleteWorkspace,
  FolderEventGetCurrentWorkspaceSetting,
  FolderEventReadCurrentWorkspace,
  FolderEventReadWorkspaceViews,
} from '@/services/backend/events/flowy-folder';
import {
  UserEventChangeWorkspaceIcon,
  UserEventGetAllWorkspace,
  UserEventOpenWorkspace,
  UserEventRenameWorkspace,
} from '@/services/backend/events/flowy-user';

export async function openWorkspace(id: string) {
  const payload = new UserWorkspaceIdPB({
    workspace_id: id,
  });

  const result = await UserEventOpenWorkspace(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
}

export async function deleteWorkspace(id: string) {
  const payload = new WorkspaceIdPB({
    value: id,
  });

  const result = await FolderEventDeleteWorkspace(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
}

export async function getWorkspaceChildViews(id: string) {
  const payload = new GetWorkspaceViewPB({
    value: id,
  });

  const result = await FolderEventReadWorkspaceViews(payload);

  if (result.ok) {
    return result.val.items.map(parserViewPBToPage);
  }

  return [];
}

export async function getWorkspaces() {
  const result = await UserEventGetAllWorkspace();

  if (result.ok) {
    return result.val.items.map((workspace) => ({
      id: workspace.workspace_id,
      name: workspace.name,
    }));
  }

  return [];
}

export async function getCurrentWorkspaceSetting() {
  const res = await FolderEventGetCurrentWorkspaceSetting();

  if (res.ok) {
    return res.val;
  }

  return;
}

export async function getCurrentWorkspace() {
  const result = await FolderEventReadCurrentWorkspace();

  if (result.ok) {
    return result.val.id;
  }

  return null;
}

export async function createCurrentWorkspaceChildView(
  params: ReturnType<typeof CreateViewPayloadPB.prototype.toObject>
) {
  const payload = CreateViewPayloadPB.fromObject(params);

  const result = await FolderEventCreateView(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
}

export async function renameWorkspace(id: string, name: string) {
  const payload = new RenameWorkspacePB({
    workspace_id: id,
    new_name: name,
  });

  const result = await UserEventRenameWorkspace(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
}

export async function changeWorkspaceIcon(id: string, icon: string) {
  const payload = new ChangeWorkspaceIconPB({
    workspace_id: id,
    new_icon: icon,
  });

  const result = await UserEventChangeWorkspaceIcon(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
}
