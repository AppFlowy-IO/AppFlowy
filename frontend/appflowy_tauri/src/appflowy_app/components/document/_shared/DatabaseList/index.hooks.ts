import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { Page } from '$app_reducers/pages/slice';
import { ViewLayoutPB } from '@/services/backend';

export function useLoadDatabaseList({ searchText, layout }: { searchText: string; layout: ViewLayoutPB }) {
  const [list, setList] = useState<Page[]>([]);
  const pages = useAppSelector((state) => state.pages.pageMap);

  useEffect(() => {
    const list = Object.values(pages)
      .map((page) => {
        return page;
      })
      .filter((page) => {
        if (page.layout !== layout) return false;
        return page.name.toLowerCase().includes(searchText.toLowerCase());
      });

    setList(list);
  }, [layout, pages, searchText]);

  return {
    list,
  };
}
