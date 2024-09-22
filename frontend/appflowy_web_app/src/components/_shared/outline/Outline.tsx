import { UIVariant, View } from '@/application/types';
import { DirectoryStructure } from '@/components/_shared/skeleton/DirectoryStructure';
import OutlineItem from '@/components/_shared/outline/OutlineItem';
import React, { memo } from 'react';

export function Outline ({ outline, width, selectedViewId, navigateToView, variant }: {
  width: number;
  outline?: View[];
  selectedViewId?: string;
  navigateToView?: (viewId: string) => Promise<void>
  variant?: UIVariant;
}) {

  return (
    <div className={'flex w-full flex-1 flex-col gap-1 py-[10px] px-[10px]'}>
      {!outline || outline.length === 0 ? <div
          style={{
            width: width - 20,
          }}
        ><DirectoryStructure /></div> :
        outline.map((view) =>
          <OutlineItem
            variant={variant}
            key={view.view_id}
            selectedViewId={selectedViewId}
            view={view}
            width={width - 20}
            navigateToView={navigateToView}
          />,
        )
      }
    </div>
  );
}

export default memo(Outline);
