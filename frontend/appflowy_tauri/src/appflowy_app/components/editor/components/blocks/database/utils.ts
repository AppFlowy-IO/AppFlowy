import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { ViewLayoutPB } from '@/services/backend';

export async function createGrid(pageId: string) {
  const pageController = new PageController(pageId);
  const newViewId = await pageController.createPage({
    layout: ViewLayoutPB.Grid,
    name: '',
  });

  return newViewId;
}
