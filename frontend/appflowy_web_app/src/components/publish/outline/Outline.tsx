import { usePublishContext } from '@/application/publish';
import emptyImageSrc from '@/assets/images/empty.png';
import { DirectoryStructure } from '@/components/_shared/skeleton/OutlineSkeleton';
import OutlineItem from '@/components/publish/outline/OutlineItem';
import React from 'react';

function Outline ({ width }: { width: number }) {
  const outline = usePublishContext()?.outline;

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
            view={view}
            width={width - 20}
          />,
        )
      }
    </div>
  );
}

export default Outline;
