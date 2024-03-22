import ViewIconGroup from '$app/components/_shared/view_title/ViewIconGroup';
import { PageCover, PageIcon } from '$app_reducers/pages/slice';
import ViewIcon from '$app/components/_shared/view_title/ViewIcon';
import { ViewCover } from '$app/components/_shared/view_title/cover';

function ViewBanner({
  icon,
  hover,
  onUpdateIcon,
  showCover,
  cover,
  onUpdateCover,
}: {
  icon?: PageIcon;
  hover: boolean;
  onUpdateIcon: (icon: string) => void;
  showCover: boolean;
  cover?: PageCover;
  onUpdateCover?: (cover?: PageCover) => void;
}) {
  return (
    <div className={'view-banner flex w-full flex-col overflow-hidden'}>
      {showCover && cover && <ViewCover cover={cover} onUpdateCover={onUpdateCover} />}

      <div className={`relative min-h-[65px] ${showCover ? 'w-[964px] min-w-0 max-w-full px-16' : ''} pt-12`}>
        <div
          style={{
            display: icon ? 'flex' : 'none',
            position: cover ? 'absolute' : 'relative',
            bottom: cover ? '24px' : 'auto',
          }}
        >
          <ViewIcon onUpdateIcon={onUpdateIcon} icon={icon} />
        </div>
        <div
          style={{
            opacity: hover ? 1 : 0,
          }}
        >
          <ViewIconGroup
            icon={icon}
            onUpdateIcon={onUpdateIcon}
            showCover={showCover}
            cover={cover}
            onUpdateCover={onUpdateCover}
          />
        </div>
      </div>
    </div>
  );
}

export default ViewBanner;
