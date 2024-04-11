import { stringToColor, stringToShortName } from '$app/utils/avatar';
import { Avatar } from '@mui/material';
import { useAppSelector } from '$app/stores/store';

export const ProfileAvatar = ({
  onClick,
  className,
  width,
  height,
}: {
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
  width?: number;
  height?: number;
  className?: string;
}) => {
  const { displayName = 'Me', iconUrl } = useAppSelector((state) => state.currentUser);

  return (
    <Avatar
      onClick={onClick}
      className={className}
      sx={{
        bgcolor: iconUrl ? 'transparent' : stringToColor(displayName),
        width,
        height,
        fontSize: iconUrl ? undefined : width ? width / 2.5 : 20,
        color: iconUrl ? undefined : 'white',
      }}
    >
      {iconUrl ? iconUrl : stringToShortName(displayName)}
    </Avatar>
  );
};
