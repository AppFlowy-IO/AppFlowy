import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import { IconButton, InputAdornment, OutlinedInput } from '@mui/material';
import { useAppSelector } from '$app/stores/store';
import React, { useState } from 'react';
import { ReactComponent as CheckIcon } from '$app/assets/select-check.svg';
import { ReactComponent as CloseIcon } from '$app/assets/close.svg';
import { ReactComponent as EditIcon } from '$app/assets/edit.svg';

import Tooltip from '@mui/material/Tooltip';
import { UserService } from '$app/application/user/user.service';
import { notify } from '$app/components/_shared/notify';
import { ProfileAvatar } from '$app/components/_shared/avatar';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import EmojiPicker from '$app/components/_shared/emoji_picker/EmojiPicker';
import Button from '@mui/material/Button';

export const Profile = () => {
  const { displayName, id } = useAppSelector((state) => state.currentUser);
  const { t } = useTranslation();
  const [isEditing, setIsEditing] = useState(false);
  const [newName, setNewName] = useState(displayName ?? 'Me');
  const [error, setError] = useState<boolean>(false);
  const [emojiPickerAnchor, setEmojiPickerAnchor] = useState<HTMLElement | null>(null);
  const openEmojiPicker = Boolean(emojiPickerAnchor);
  const handleSave = async () => {
    setError(false);
    if (!newName) {
      setError(true);
      return;
    }

    if (newName === displayName) {
      setIsEditing(false);
      return;
    }

    try {
      await UserService.updateUserProfile({
        id,
        name: newName,
      });
      setIsEditing(false);
    } catch {
      setError(true);
      notify.error(t('newSettings.myAccount.updateNameError'));
    }
  };

  const handleEmojiSelect = async (emoji: string) => {
    try {
      await UserService.updateUserProfile({
        id,
        icon_url: emoji,
      });
    } catch {
      notify.error(t('newSettings.myAccount.updateIconError'));
    }
  };

  const handleCancel = () => {
    setNewName(displayName ?? 'Me');
    setIsEditing(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.stopPropagation();
      e.preventDefault();
      void handleSave();
    }

    if (e.key === 'Escape') {
      e.stopPropagation();
      e.preventDefault();
      handleCancel();
    }
  };

  return (
    <div className={'mt-2'}>
      <Typography className={'mb-2 font-semibold'} variant={'subtitle1'}>
        {t('newSettings.myAccount.profileLabel')}
      </Typography>
      <div className={'flex w-full items-center gap-2'}>
        <Button
          onClick={(e) => {
            setEmojiPickerAnchor(e.currentTarget);
          }}
          variant={'outlined'}
          color={'inherit'}
          className={'h-12 w-12 min-w-[48px] rounded-full'}
        >
          <ProfileAvatar className={'border border-bg-body'} width={46} height={46} />
        </Button>

        <div className={'flex-1'}>
          {isEditing ? (
            <OutlinedInput
              onKeyDown={handleKeyDown}
              error={error}
              size={'small'}
              onChange={(e) => setNewName(e.target.value)}
              spellCheck={false}
              autoFocus={true}
              autoCorrect={'off'}
              autoCapitalize={'off'}
              fullWidth
              endAdornment={
                <InputAdornment position='end'>
                  <div className={'flex items-center gap-1'}>
                    <Tooltip title={t('button.save')}>
                      <IconButton
                        color={'primary'}
                        disabled={!newName || newName === displayName}
                        onClick={handleSave}
                        size={'small'}
                      >
                        <CheckIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={t('button.cancel')}>
                      <IconButton onClick={handleCancel} edge='end' size={'small'}>
                        <CloseIcon />
                      </IconButton>
                    </Tooltip>
                  </div>
                </InputAdornment>
              }
              sx={{
                '&.MuiOutlinedInput-root': {
                  borderRadius: '8px',
                },
              }}
              placeholder={t('newSettings.myAccount.profileNamePlaceholder')}
              value={newName}
            />
          ) : (
            <Typography className={'font-semibold'} variant={'subtitle2'}>
              {newName}
              <Tooltip title={t('button.edit')} placement={'top'}>
                <IconButton onClick={() => setIsEditing(true)} size={'small'} className={'ml-1'}>
                  <EditIcon />
                </IconButton>
              </Tooltip>
            </Typography>
          )}
        </div>
      </div>
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
            vertical: 'bottom',
            horizontal: 'left',
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
