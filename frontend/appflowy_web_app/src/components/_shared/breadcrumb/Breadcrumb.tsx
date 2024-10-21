import { UIVariant, View } from '@/application/types';
import BreadcrumbItem from '@/components/_shared/breadcrumb/BreadcrumbItem';
import BreadcrumbMoreModal from '@/components/_shared/breadcrumb/BreadcrumbMoreModal';
import { getPlatform } from '@/utils/platform';
import { IconButton } from '@mui/material';
import React, { memo, useMemo } from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';

export interface BreadcrumbProps {
  crumbs: View[];
  toView?: (viewId: string) => Promise<void>;
  variant?: UIVariant;
}

export function Breadcrumb ({ crumbs, toView, variant }: BreadcrumbProps) {
  const [openMore, setOpenMore] = React.useState(false);
  const renderCrumb = useMemo(() => {
    const tailCount = getPlatform().isMobile ? 1 : 2;

    if (crumbs.length > tailCount + 1) {
      const firstCrumb = crumbs[0];
      const lastCrumbs = crumbs.slice(-tailCount);

      return <>
        <div className={'text-text-title flex max-w-[160px] min-w-0 truncate items-center gap-2'}>
          <BreadcrumbItem
            variant={variant}
            toView={toView}
            crumb={firstCrumb}
            disableClick={true}
          />
          <RightIcon className={'h-4 shrink-0 w-4'} />
        </div>
        <div className={'text-text-title flex shrink-0 max-w-[160px] min-w-0 truncate items-center gap-2'}>
          <IconButton
            onClick={() => {
              setOpenMore(true);
            }}
          >
            <MoreIcon className={'h-5 shrink-0 w-5'} />
          </IconButton>

          <RightIcon className={'h-4 shrink-0 w-4'} />
        </div>
        {lastCrumbs.map((crumb, index) => {
          const key = `${crumb.view_id}-${index}`;

          return (
            <div
              className={'text-text-title flex max-w-[160px] min-w-0 truncate items-center gap-2'}
              key={key}
            >
              <BreadcrumbItem
                variant={variant}
                toView={toView}
                crumb={crumb}
                disableClick={false}
              />
              {index === lastCrumbs.length - 1 ? null : <RightIcon className={'h-4 shrink-0 w-4'} />}
            </div>
          );
        })}

      </>;
    }

    return crumbs?.map((crumb, index) => {
      const isLast = index === crumbs.length - 1;
      const key = `${crumb.view_id}-${index}`;

      return (
        <div
          className={`${isLast ? 'text-text-title' : 'text-text-caption'} flex max-w-[160px] min-w-0 truncate items-center gap-2`}
          key={key}
        >
          <BreadcrumbItem
            variant={variant}
            toView={toView}
            crumb={crumb}
            disableClick={isLast}
          />
          {!isLast && <RightIcon className={'h-4 shrink-0 w-4'} />}
        </div>
      );
    });
  }, [crumbs, toView, variant]);

  return (
    <div className={'relative h-full w-full flex-1 overflow-hidden flex items-center gap-2'}>
      {renderCrumb}
      <BreadcrumbMoreModal
        open={openMore}
        onClose={() => setOpenMore(false)}
        crumbs={crumbs}
        toView={toView}
      />
    </div>
  );
}

export default memo(Breadcrumb);
