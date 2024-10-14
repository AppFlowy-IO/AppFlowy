import { notify } from '@/components/_shared/notify';
import { Popover } from '@/components/_shared/popover';
import { copyTextToClipboard } from '@/utils/copy';
import { Button, Divider, Portal, Tooltip } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import * as React from 'react';
import Box from '@mui/material/Box';
import { ReactComponent as SpeedDialIcon } from '@/assets/help.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as WhatsNewIcon } from '@/assets/star.svg';
import { ReactComponent as SupportIcon } from '@/assets/message_support.svg';
import { ReactComponent as DebugIcon } from '@/assets/debug.svg';
import { ReactComponent as FeedbackIcon } from '@/assets/report.svg';

const popoverProps: Partial<PopoverProps> = {
  anchorOrigin: {
    vertical: 'top',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: 'bottom',
    horizontal: 'right',
  },
};

export default function Help () {
  const ref = React.useRef<HTMLDivElement | null>(null);
  const [open, setOpen] = React.useState(false);
  const { t } = useTranslation();

  return (
    <Portal>
      <Box
        className={'fixed bottom-6 right-6'}
        sx={{ transform: 'translateZ(0px)', flexGrow: 1 }}
      >
        <Tooltip title={t('questionBubble.help')}>
          <div
            ref={ref}
            onClick={() => setOpen(!open)}
            className={'w-9 h-9 rounded-full flex items-center justify-center border border-line-border bg-bg-body hover:bg-fill-list-hover cursor-pointer shadow-md'}
          >
            <SpeedDialIcon className={'w-4 h-4'} />
          </div>
        </Tooltip>
        <Popover {...popoverProps} open={open}
                 anchorEl={ref.current}
                 onClose={() => setOpen(false)}
        >
          <div className={'flex flex-col gap-1 w-[240px] h-fit p-2'}>
            <Button
              component={'a'}
              target="_blank"
              href={'https://www.appflowy.io/what-is-new'}
              className={'justify-start'}
              color={'inherit'}
              startIcon={<WhatsNewIcon />}
              variant={'text'}
            >{t('questionBubble.whatsNew')}
            </Button>
            <Button
              component={'a'}
              href={'https://discord.gg/9Q2xaN37tV'}
              className={'justify-start'}
              target="_blank"
              color={'inherit'}
              startIcon={<SupportIcon />}
              variant={'text'}
            >{t('questionBubble.help')}
            </Button>
            <Button
              onClick={() => {
                const info = {
                  platform: 'web',
                  url: window.location.href,
                  userAgent: navigator.userAgent,

                };

                void copyTextToClipboard(JSON.stringify(info, null, 2));
                notify.success(t('questionBubble.debug.success'));
              }}
              className={'justify-start'}
              color={'inherit'}
              startIcon={<DebugIcon />}
              variant={'text'}
            >{t('questionBubble.debug.name')}
            </Button>
            <Button
              component={'a'}
              target="_blank"
              href={'https://github.com/AppFlowy-IO/AppFlowy/issues/new/choose'}
              className={'justify-start'}
              color={'inherit'}
              startIcon={<FeedbackIcon />}
              variant={'text'}
            >{t('questionBubble.feedback')}
            </Button>
            <Divider />
            <Button
              size={'small'}
              target="_blank"
              component={'a'}
              href={'https://forum.appflowy.io/'}
              className={'justify-start text-text-caption'}
              color={'inherit'}
              variant={'text'}
            >Community Forum
            </Button>
            <Button
              size={'small'}
              component={'a'}
              target="_blank"
              href={'https://x.com/appflowy'}
              className={'justify-start text-text-caption'}
              color={'inherit'}
              variant={'text'}
            >Twitter - @appflowy
            </Button>
            <Button
              size={'small'}
              component={'a'}
              target="_blank"
              href={'https://www.reddit.com/r/AppFlowy/'}
              className={'justify-start text-text-caption'}
              color={'inherit'}
              variant={'text'}
            >Reddit - r/appflowy
            </Button>
          </div>
        </Popover>
      </Box>
    </Portal>

  );
}
