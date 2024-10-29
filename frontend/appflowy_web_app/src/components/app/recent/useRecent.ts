import { useAppRecent } from '@/components/app/app.hooks';
import { useEffect } from 'react';

export function useRecent () {
  const {
    recentViews,
    loadRecentViews,
  } = useAppRecent();

  useEffect(() => {
    void loadRecentViews?.();
  }, [loadRecentViews]);

  return {
    views: recentViews,
  };
}