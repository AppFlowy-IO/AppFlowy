import { useAppSelector } from '$app/stores/store';
import { ViewLayoutPB } from '@/services/backend';

export function useLoadDatabaseList({ searchText, layout }: { searchText: string; layout: ViewLayoutPB }) {
  const list = useAppSelector((state) => {
    return Object.values(state.pages.pageMap).filter((page) => {
      if (page.layout !== layout) return false;
      return page.name.toLowerCase().includes(searchText.toLowerCase());
    });
  });

  return {
    list,
  };
}
