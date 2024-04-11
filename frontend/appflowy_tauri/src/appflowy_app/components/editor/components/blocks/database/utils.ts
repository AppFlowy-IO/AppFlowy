import { ViewLayoutPB } from '@/services/backend';
import { createPage } from '$app/application/folder/page.service';

export async function createGrid(pageId: string) {
  const newViewId = await createPage({
    layout: ViewLayoutPB.Grid,
    name: '',
    parent_view_id: pageId,
  });

  return newViewId;
}
