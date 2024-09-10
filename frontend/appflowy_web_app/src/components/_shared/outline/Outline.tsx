import { View } from '@/application/types';
import emptyImageSrc from '@/assets/images/empty.png';
import { DirectoryStructure } from '@/components/_shared/skeleton/OutlineSkeleton';
import OutlineItem from '@/components/_shared/outline/OutlineItem';
import React, { memo } from 'react';

export function Outline ({ outline, width, selectedViewId, navigateToView }: {
  width: number;
  outline?: View;
  selectedViewId?: string;
  navigateToView?: (viewId: string) => Promise<void>
}) {

  const isEmpty = outline && outline.children.length === 0;

  return (
    <div className={'flex w-full flex-1 flex-col gap-1 py-[10px] px-[10px]'}>
      {isEmpty && <img src={emptyImageSrc} alt={'No data found'} className={'mx-auto h-[200px]'} />}
      {!outline ? <div style={{
          width: width - 20,
        }}
        ><DirectoryStructure /></div> :
        outline.children.map((view) =>
          <OutlineItem
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
