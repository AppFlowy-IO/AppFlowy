import ViewIconGroup from '$app/components/_shared/ViewTitle/ViewIconGroup';
import { PageIcon } from '$app_reducers/pages/slice';
import ViewIcon from '$app/components/_shared/ViewTitle/ViewIcon';

function ViewBanner({
  icon,
  hover,
  onUpdateIcon,
}: {
  icon?: PageIcon;
  hover: boolean;
  onUpdateIcon: (icon: string) => void;
}) {
  return (
    <>
      <div
        style={{
          display: icon ? 'flex' : 'none',
        }}
      >
        <ViewIcon onUpdateIcon={onUpdateIcon} icon={icon} />
      </div>
      <div
        style={{
          opacity: hover ? 1 : 0,
        }}
      >
        <ViewIconGroup icon={icon} onUpdateIcon={onUpdateIcon} />
      </div>
    </>
  );
}

export default ViewBanner;
