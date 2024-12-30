import { Popover } from '@/components/_shared/popover';
import AddCreator from '@/components/as-template/creator/AddCreator';
import CreatorAvatar from '@/components/as-template/creator/CreatorAvatar';
import CreatorItem from '@/components/as-template/creator/CreatorItem';
import { useLoadCreators } from '@/components/as-template/hooks';
import { accountLinkIcon } from '@/components/as-template/icons';
import { CircularProgress, OutlinedInput, Tooltip, Typography, Button } from '@mui/material';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ArrowRight } from '@/assets/arrow_right.svg';

const ITEM_HEIGHT = 48;
const ITEM_PADDING_TOP = 8;
const MenuProps = {
  disableAutoFocus: true,
  disableRestoreFocus: true,
  disableEnforceFocus: true,
  PaperProps: {
    className: 'p-2 appflowy-scroller',
  },
};

function Creator ({ value, onChange }: {
  value?: string;
  onChange: (value: string) => void;
}) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLButtonElement>(null);

  const [searchText, setSearchText] = useState('');
  const {
    creators,
    loading,
    loadCreators,
  } = useLoadCreators({
    searchText,
  });

  useEffect(() => {
    void loadCreators();
  }, [loadCreators]);

  useEffect(() => {
    if (!value && creators[0]) {
      onChange(creators[0].id);
    }
  }, [creators, value, onChange]);

  const handleSelect = useCallback((id: string) => {
    onChange(id);
    setOpen(false);
  }, [onChange]);

  const selectedCreator = useMemo(() => creators.find((creator) => creator.id === value), [creators, value]);

  return (
    <div className={'flex flex-col gap-4'}>
      <Typography variant={'h6'} className={'text-text-caption'}>{t('template.creator.label')}</Typography>
      <div className={'flex gap-4 flex-col'}>
        <Button
          variant={'outlined'}
          color={'inherit'}
          ref={ref}
          className={'flex items-center gap-2 justify-between'}
          onClick={() => {
            setOpen(true);
          }}
        >
          <CreatorAvatar size={40} src={selectedCreator?.avatar_url || ''} name={selectedCreator?.name || ''} />
          <div className={'text-left flex-1'}>{selectedCreator?.name}</div>
          <ArrowRight className={'rotate-90 text-text-caption'} />
        </Button>

        <div className={'flex flex-wrap gap-2'}>
          {selectedCreator?.account_links?.map((link) => {
            return (
              <Tooltip title={link.url} key={link.link_type} placement={'top'} arrow>
                <a href={link.url} key={link.link_type} target={'_blank'}
                   className={'flex w-10 h-10 items-center justify-between p-3 rounded-full border border-line-border hover:border-content-blue-400 hover:text-content-blue-400'}
                >
                  {accountLinkIcon(link.link_type)}
                </a>
              </Tooltip>
            );
          })}
        </div>
        <Popover {...MenuProps} open={open} anchorEl={ref.current} onClose={() => setOpen(false)}>
          <div className={'flex flex-col gap-2'} style={{
            minWidth: ref.current?.clientWidth,
            maxHeight: ITEM_HEIGHT * 10 + ITEM_PADDING_TOP,
          }}
          >
            <OutlinedInput
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              endAdornment={
                loading ? <CircularProgress size={'small'} /> : null
              }
              size={'small'}
              className={'bg-bg-body flex-1'}
              placeholder={t('template.creator.typeToSearch')}
            />
            <AddCreator searchText={searchText} onCreated={loadCreators} />
            {
              creators.map((creator) => {
                return (
                  <CreatorItem
                    key={creator.id}
                    creator={creator}
                    onClick={() => handleSelect(creator.id)}
                    reloadCreators={loadCreators}
                    selected={selectedCreator?.id === creator.id}
                  />
                );
              })
            }
          </div>

        </Popover>
      </div>

    </div>
  );
}

export default Creator;

