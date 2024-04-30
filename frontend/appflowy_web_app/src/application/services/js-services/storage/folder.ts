import { YjsEditorKey } from '@/application/collab.type';
import { openCollabDB } from '@/application/services/js-services/db';
import { getAuthInfo } from '@/application/services/js-services/storage/token';

export async function getFolderStorage(workspaceId: string) {
  const docName = getDocName(workspaceId);
  const doc = await openCollabDB(docName);
  const localExist = doc.share.has(YjsEditorKey.data_section);

  return {
    doc,
    localExist,
  };
}

export function getDocName(workspaceId: string) {
  const { uuid } = getAuthInfo() || {};

  if (!uuid) throw new Error('No user found');
  return `${uuid}_folder_${workspaceId}`;
}
