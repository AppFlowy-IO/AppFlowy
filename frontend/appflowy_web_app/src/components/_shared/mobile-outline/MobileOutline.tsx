import { UIVariant, View } from '@/application/types';
import OutlineItem from './OutlineItem';
import React from 'react';

export function MobileOutline ({
  outline,
  variant,
  selectedViewId,
  navigateToView,
  onClose,
}: {
  outline: View[];
  variant?: UIVariant;
  selectedViewId?: string;
  navigateToView?: (viewId: string) => Promise<void>;
  onClose: () => void;
}) {
  return (
    <div className={'flex w-full flex-1 flex-col gap-2 py-[10px]'}>
      {outline.map((view) =>
        <OutlineItem
          variant={variant}
          key={view.view_id}
          selectedViewId={selectedViewId}
          view={view}
          navigateToView={async (viewId: string) => {
            await navigateToView?.(viewId);
            onClose();
          }}
        />,
      )}
    </div>
  );
}

export default MobileOutline;