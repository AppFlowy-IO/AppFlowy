import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import ViewItem from '@/components/app/outline/ViewItem';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { View } from '@/application/types';
import { ReactComponent as PrivateIcon } from '@/assets/lock.svg';

function SpaceItem({
  view,
  width,
  renderExtra,
  expandIds,
  toggleExpand,
  onClickView,
  onClickSpace,
}: {
  view: View;
  width: number;
  expandIds: string[];
  toggleExpand: (id: string, isExpand: boolean) => void;
  renderExtra?: ({
    hovered,
    view,
  }: {
    hovered: boolean;
    view: View
  }) => React.ReactNode;
  onClickView?: (viewId: string) => void;
  onClickSpace?: (viewId: string) => void;
}) {
  const [hovered, setHovered] = React.useState<boolean>(false);
  const isExpanded = expandIds.includes(view.view_id);
  const isPrivate = view.is_private;
  const renderItem = useMemo(() => {
    if (!view) return null;
    const extra = view?.extra;
    const name = view?.name || '';

    return (
      <div
        style={{
          width,
        }}
        onClick={() => {
          toggleExpand(view.view_id, !isExpanded);
          onClickSpace?.(view.view_id);
        }}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        className={
          'flex items-center select-none px-1 truncate cursor-pointer min-h-[34px] w-full gap-0.5 rounded-[8px] py-1.5  text-sm hover:bg-fill-list-hover focus:bg-content-blue-50 focus:outline-none'
        }
      >
        <SpaceIcon
          className={'icon !rounded-[8px] !h-[22px] mr-1.5 !w-[22px]'}
          bgColor={extra?.space_icon_color}
          value={extra?.space_icon || ''}
          char={extra?.space_icon ? undefined : name.slice(0, 1)}
        />
        <Tooltip
          title={name}
          disableInteractive={true}
        >
          <div className={'items-center gap-1 text-sm flex-1 justify-start flex overflow-hidden'}>
            <div className={'truncate w-auto font-medium'}>{name}</div>

            {isPrivate &&
              <div className={'h-4 w-4 text-base min-w-4 text-text-title opacity-80'}>
                <PrivateIcon/>
              </div>
            }
          </div>
        </Tooltip>
        {
          renderExtra && renderExtra({ hovered, view })}
      </div>
    );
  }, [hovered, isExpanded, isPrivate, onClickSpace, renderExtra, toggleExpand, view, width]);

  const renderChildren = useMemo(() => {
    return <div
      className={'flex transform flex-col gap-2 transition-all'}
      style={{
        display: isExpanded ? 'block' : 'none',
      }}
    >{
      view?.children?.map((child) => (
        <ViewItem
          key={child.view_id}
          view={child}
          width={width}
          renderExtra={renderExtra}
          expandIds={expandIds}
          toggleExpand={toggleExpand}
          onClickView={onClickView}
        />
      ))
    }</div>;
  }, [onClickView, isExpanded, view?.children, width, renderExtra, expandIds, toggleExpand]);

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem}
      {renderChildren}
    </div>
  );
}

export default SpaceItem;