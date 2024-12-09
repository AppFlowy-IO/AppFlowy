import { ViewIconType } from '@/application/types';
import { EmojiPicker } from '@/components/_shared/emoji-picker';
import IconPicker from '@/components/_shared/icon-picker/IconPicker';
import { Popover } from '@/components/_shared/popover';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { Button } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';

function ChangeIconPopover ({
  open,
  anchorEl,
  onClose,
  defaultType,
  emojiEnabled = true,
  iconEnabled = true,
  popoverProps = {},
  onSelectIcon,
  removeIcon,
  anchorPosition,
  hideRemove
}: {
  open: boolean,
  anchorEl?: HTMLElement | null,
  anchorPosition?: PopoverProps['anchorPosition'],
  onClose: () => void,
  defaultType: 'emoji' | 'icon',
  emojiEnabled?: boolean,
  iconEnabled?: boolean,
  popoverProps?: Partial<PopoverProps>,
  onSelectIcon?: (icon: { ty: ViewIconType, value: string, color?: string }) => void,
  removeIcon?: () => void,
  hideRemove?: boolean,
}) {
  const [value, setValue] = useState(defaultType);
  const { t } = useTranslation();

  return (
    <Popover
      onClose={onClose}
      open={open}
      anchorEl={anchorEl}
      {...popoverProps}
      anchorPosition={anchorPosition}
      anchorReference={anchorPosition ? 'anchorPosition' : 'anchorEl'}
    >
      <div className={'border-b border-line-divider px-4 pt-2 flex items-center justify-between'}>
        <ViewTabs
          onChange={(_e, newValue) => setValue(newValue)}
          value={value}
          className={'flex-1 mb-[-2px]'}
        >
          {
            iconEnabled && (
              <ViewTab
                className={'flex items-center flex-row justify-center gap-1.5'}
                value={'icon'}
                label={t('space.spaceIcon')}
              />
            )
          }
          {
            emojiEnabled && (
              <ViewTab
                className={'flex items-center flex-row justify-center gap-1.5'}
                value={'emoji'}
                label={'Emojis'}
              />
            )
          }

        </ViewTabs>
        {!hideRemove && <Button
          variant={'text'}
          color={'inherit'}
          size={'small'}
          className={'p-1 h-auto min-h-fit'}
          onClick={() => {
            removeIcon?.();
          }}
        >
          {t('button.remove')}
        </Button>}

      </div>

      {iconEnabled && <TabPanel
        index={'icon'}
        value={value}
      >
        <IconPicker
          onEscape={onClose}
          onSelect={(icon) => {
            onSelectIcon?.({
              ty: ViewIconType.Icon,
              ...icon,
            });
            onClose();
          }}
        />
      </TabPanel>}
      {emojiEnabled && <TabPanel
        index={'emoji'}
        value={value}
      >
        <EmojiPicker
          onEmojiSelect={(emoji: string) => {
            onSelectIcon?.({
              ty: ViewIconType.Emoji,
              value: emoji,
            });
          }}
          onEscape={onClose}
          hideRemove
        />
      </TabPanel>}
    </Popover>
  );
}

export default ChangeIconPopover;