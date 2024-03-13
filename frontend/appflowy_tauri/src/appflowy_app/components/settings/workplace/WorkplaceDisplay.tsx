import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import { Divider, OutlinedInput } from '@mui/material';
import React, { useState } from 'react';
import Button from '@mui/material/Button';
import { useAppSelector } from '$app/stores/store';
import { changeWorkspaceIcon, renameWorkspace } from '$app/application/folder/workspace.service';
import { notify } from '$app/components/_shared/notify';
import { WorkplaceAvatar } from '$app/components/_shared/avatar';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import EmojiPicker from '$app/components/_shared/emoji_picker/EmojiPicker';

export const WorkplaceDisplay = () => {
  const { t } = useTranslation();
  const isLocal = useAppSelector((state) => state.currentUser.isLocal);
  const workspace = useAppSelector((state) => state.workspace.currentWorkspace);
  const [name, setName] = useState(workspace?.name ?? '');
  const [emojiPickerAnchor, setEmojiPickerAnchor] = useState<HTMLElement | null>(null);
  const openEmojiPicker = Boolean(emojiPickerAnchor);
  const handleSave = async () => {
    if (!workspace || !name) return;
    try {
      await renameWorkspace(workspace.id, name);
    } catch {
      notify.error(t('newSettings.workplace.renameError'));
    }
  };

  const handleEmojiSelect = async (icon: string) => {
    if (!workspace) return;
    try {
      await changeWorkspaceIcon(workspace.id, icon);
    } catch {
      notify.error(t('newSettings.workplace.updateIconError'));
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.stopPropagation();
      e.preventDefault();
      void handleSave();
    }
  };

  return (
    <div className={'mb-1 mt-2'}>
      <Typography className={'mb-2 font-semibold'} variant={'subtitle1'}>
        {t('newSettings.workplace.workplaceName')}
      </Typography>
      <div className={'flex gap-2'}>
        <div className={'flex-1'}>
          <OutlinedInput
            size={'small'}
            spellCheck={false}
            autoCorrect={'off'}
            autoCapitalize={'off'}
            onKeyDown={handleKeyDown}
            fullWidth
            readOnly={isLocal}
            onChange={(e) => setName(e.target.value)}
            sx={{
              '&.MuiOutlinedInput-root': {
                borderRadius: '8px',
              },
            }}
            placeholder={t('newSettings.workplace.workplaceNamePlaceholder')}
            value={name}
          />
        </div>
        <Button onClick={handleSave} disabled={!name || workspace?.name === name} variant={'contained'}>
          {t('button.save')}
        </Button>
      </div>
      <Divider className={'my-3'} />
      <Typography className={'font-semibold'} variant={'subtitle1'}>
        {t('newSettings.workplace.workplaceIcon')}
      </Typography>
      <Typography variant={'body2'} className={'my-2 text-text-caption'}>
        {t('newSettings.workplace.workplaceIconSubtitle')}
      </Typography>
      <Button
        onClick={(e) => {
          setEmojiPickerAnchor(e.currentTarget);
        }}
        variant={'outlined'}
        color={'inherit'}
        className={'h-16 w-16 rounded-lg p-0'}
        disabled={isLocal}
      >
        <WorkplaceAvatar
          workplaceName={name}
          width={62}
          height={62}
          className={'rounded-lg border border-bg-body p-[2px] hover:opacity-90'}
        />
      </Button>
      {openEmojiPicker && (
        <Popover
          {...PopoverCommonProps}
          className={'border-none bg-transparent shadow-none'}
          anchorEl={emojiPickerAnchor}
          disableAutoFocus={true}
          open={openEmojiPicker}
          onClose={() => {
            setEmojiPickerAnchor(null);
          }}
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
        >
          <EmojiPicker
            onEscape={() => {
              setEmojiPickerAnchor(null);
            }}
            onEmojiSelect={handleEmojiSelect}
          />
        </Popover>
      )}
    </div>
  );
};
