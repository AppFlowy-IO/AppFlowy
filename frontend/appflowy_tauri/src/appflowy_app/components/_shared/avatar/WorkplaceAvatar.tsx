import { Avatar } from '@mui/material';
import { stringToColor, stringToShortName } from '$app/utils/avatar';

export const WorkplaceAvatar = ({
  workplaceName,
  icon,
  onClick,
  width,
  height,
  className,
}: {
  workplaceName: string;
  width: number;
  height: number;
  className?: string;
  icon?: string;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
}) => {
  return (
    <Avatar
      onClick={onClick}
      className={className}
      variant={'rounded'}
      sx={{
        bgcolor: icon ? 'transparent' : stringToColor(workplaceName),
        width,
        height,
        color: icon ? undefined : 'white',
      }}
    >
      {icon ? icon : stringToShortName(workplaceName)}
    </Avatar>
  );
};
