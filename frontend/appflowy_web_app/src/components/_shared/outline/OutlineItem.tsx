import { UIVariant, View } from '@/application/types';
import { ReactComponent as PrivateIcon } from '@/assets/lock.svg';
import OutlineIcon from '@/components/_shared/outline/OutlineIcon';
import OutlineItemContent from '@/components/_shared/outline/OutlineItemContent';
import { getOutlineExpands, setOutlineExpands } from '@/components/_shared/outline/utils';
import React, { useCallback, useEffect, useMemo } from 'react';

function OutlineItem({ view, level = 0, width, navigateToView, selectedViewId, variant }: {
  view: View;
  width?: number;
  level?: number;
  selectedViewId?: string;
  navigateToView?: (viewId: string) => Promise<void>
  variant?: UIVariant;
}) {
  const selected = selectedViewId === view.view_id;
  const [isExpanded, setIsExpanded] = React.useState(() => {
    return getOutlineExpands()[view.view_id] || false;
  });

  useEffect(() => {
    setOutlineExpands(view.view_id, isExpanded);
  }, [isExpanded, view.view_id]);

  const getIcon = useCallback(() => {
    return <span className={'text-sm mt-1'}><OutlineIcon
      level={level}
      isExpanded={isExpanded}
      setIsExpanded={setIsExpanded}
    /></span>;
  }, [isExpanded, level]);

  const renderItem = useCallback((item: View) => {
    return (
      <div
        className={`flex ${variant === UIVariant.App ? 'folder-view-item' : ''} h-fit my-0.5 w-full justify-between gap-2`}
      >
        <div
          style={{
            width,
            backgroundColor: selected ? 'var(--fill-list-hover)' : undefined,
          }}
          id={`${variant}-view-${item.view_id}`}
          className={
            'flex items-center min-h-[34px] w-full gap-0.5 rounded-[8px] py-1.5 px-0.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.children?.length ? getIcon() : null}

          <OutlineItemContent
            variant={variant}
            item={item}
            navigateToView={navigateToView}
            level={level}
            setIsExpanded={setIsExpanded}
          />
          {item.is_private && <PrivateIcon className={'h-4 w-4 text-text-caption'}/>}
        </div>
      </div>
    );
  }, [variant, width, selected, getIcon, navigateToView, level]);

  const children = useMemo(() => view.children || [], [view.children]);

  const renderChildren = useMemo(() => {
    return <div
      className={'flex transform flex-col gap-2 transition-all'}
      style={{
        display: isExpanded ? 'block' : 'none',
      }}
    >
      {children
        .map((item, index) => (
          <OutlineItem
            selectedViewId={selectedViewId}
            navigateToView={navigateToView}
            level={level + 1}
            width={width}
            key={index}
            view={item}
            variant={variant}
          />
        ))}
    </div>;
  }, [children, isExpanded, level, navigateToView, selectedViewId, width, variant]);

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem(view)}
      {renderChildren}
    </div>
  );
}

export default OutlineItem;
