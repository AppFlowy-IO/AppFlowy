import * as React from 'react';
import SpeedDial from '@mui/material/SpeedDial';
import SpeedDialIcon from '@mui/material/SpeedDialIcon';
import SpeedDialAction from '@mui/material/SpeedDialAction';
import { useMemo } from 'react';
import { CloseOutlined, BuildOutlined, LoginOutlined, VisibilityOff } from '@mui/icons-material';
import ManualSignInDialog from '$app/components/_shared/devtool/ManualSignInDialog';
import { Portal } from '@mui/material';

function AppFlowyDevTool() {
  const [openManualSignIn, setOpenManualSignIn] = React.useState(false);
  const [hidden, setHidden] = React.useState(false);
  const actions = useMemo(
    () => [
      {
        icon: <LoginOutlined />,
        name: 'Manual SignIn',
        onClick: () => {
          setOpenManualSignIn(true);
        },
      },
      {
        icon: <VisibilityOff />,
        name: 'Hide Dev Tool',
        onClick: () => {
          setHidden(true);
        },
      },
    ],
    []
  );

  return (
    <Portal>
      <SpeedDial
        hidden={hidden}
        direction={'left'}
        draggable={true}
        title={'AppFlowy Dev Tool'}
        ariaLabel='SpeedDial basic example'
        sx={{ position: 'absolute', zIndex: 1500, top: 64, right: 16 }}
        icon={<SpeedDialIcon className={'text-content-on-fill'} openIcon={<CloseOutlined />} icon={<BuildOutlined />} />}
      >
        {actions.map((action) => (
          <SpeedDialAction onClick={action.onClick} key={action.name} icon={action.icon} tooltipTitle={action.name} />
        ))}

        {openManualSignIn && (
          <ManualSignInDialog
            open={openManualSignIn}
            onClose={() => {
              setOpenManualSignIn(false);
            }}
          />
        )}
      </SpeedDial>
    </Portal>
  );
}

export default AppFlowyDevTool;
