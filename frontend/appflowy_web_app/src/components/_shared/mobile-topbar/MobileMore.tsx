import { Popover } from '@/components/_shared/popover';
import React, { useMemo } from 'react';
import { ReactComponent as MoreIcon } from '@/assets/settings_more.svg';
import { Button, Divider, IconButton } from '@mui/material';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as SupportIcon } from '@/assets/message_support.svg';

function MobileMore ({
  onClose,
}: {
  onClose: () => void;
}) {
  const [openMore, setOpenMore] = React.useState(false);
  const ref = React.useRef<HTMLButtonElement | null>(null);
  const { t } = useTranslation();
  const navigate = useNavigate();
  const actions = useMemo(() => {
    return [
      {
        label: t('template.label'),
        icon: <TemplateIcon />,
        onClick: () => {
          window.open('https://appflowy.io/templates', '_blank');
        },
      },
      {
        label: t('trash.text'),
        icon: <TrashIcon />,
        onClick: () => {
          navigate('/app/trash');
        },
      }, {
        label: t('questionBubble.help'),
        onClick: () => {
          window.open('https://discord.gg/9Q2xaN37tV', '_blank');
        },
        icon: <SupportIcon />,
      },
    ];
  }, [navigate, t]);

  return (
    <>
      <IconButton
        ref={ref}
        onClick={() => setOpenMore(true)}
        size={'large'}
        className={'p-2'}
      >
        <MoreIcon className={'h-5 w-5 text-text-title'} />
      </IconButton>
      <Popover
        open={openMore}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
        anchorEl={ref.current}
        onClose={() => setOpenMore(false)}
      >
        <div className={'flex flex-col w-[200px] justify-start gap-3 py-3'}>
          {actions.map((action, index) => (
            <div
              key={index}
            >
              <Button
                startIcon={action.icon}
                onClick={() => {
                  action.onClick();
                  setOpenMore(false);
                  onClose();
                }}
                variant={'text'}
                className={'flex-1 gap-2 font-normal px-4 justify-start py-1 text-base'}
                color={'inherit'}
              >
                {action.label}
              </Button>
              {index !== actions.length - 1 && <Divider className={'w-full mt-2 opacity-50'} />}

            </div>

          ))}
        </div>
      </Popover>
    </>
  );
}

export default MobileMore;