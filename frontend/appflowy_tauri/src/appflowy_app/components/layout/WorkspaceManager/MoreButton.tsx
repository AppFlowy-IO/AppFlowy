import React, { useMemo } from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import { IconButton } from '@mui/material';
import MoreIcon from '@mui/icons-material/MoreHoriz';
import SettingsIcon from '@mui/icons-material/Settings';
import { useTranslation } from 'react-i18next';
import { DeleteOutline } from '@mui/icons-material';
import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';

function MoreButton({
  workspace,
  isHovered,
  onDelete,
}: {
  isHovered: boolean;
  workspace: WorkspaceItem;
  onDelete: (id: string) => void;
}) {
  const { t } = useTranslation();

  const options = useMemo(() => {
    return [
      {
        key: 'settings',
        icon: <SettingsIcon />,
        label: t('settings.title'),
        onClick: () => {
          //
        },
      },
      {
        key: 'delete',
        icon: <DeleteOutline />,
        label: t('button.delete'),
        onClick: () => onDelete(workspace.id),
      },
    ];
  }, [onDelete, t, workspace.id]);

  return (
    <>
      <ButtonPopoverList
        isVisible={isHovered}
        popoverOrigin={{
          anchorOrigin: {
            vertical: 'bottom',
            horizontal: 'left',
          },
          transformOrigin: {
            vertical: 'top',
            horizontal: 'left',
          },
        }}
        popoverOptions={options}
      >
        <IconButton>
          <MoreIcon />
        </IconButton>
      </ButtonPopoverList>
    </>
  );
}

export default MoreButton;
