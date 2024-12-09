import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';
import { QuickNote } from '@/components/app/quick-note';

function SideBarBottom () {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <div
      className={'flex border-t border-line-divider py-4 px-4 gap-1 justify-around items-center sticky bottom-0 bg-bg-base'}
    >
      <Tooltip title={t('template.label')}>
        <IconButton
          size={'small'}
          onClick={() => {
            window.open('https://appflowy.io/templates', '_blank');
          }}
        >
          <TemplateIcon />
        </IconButton>
      </Tooltip>

      <Tooltip title={t('trash.text')}>
        <IconButton
          size={'small'}
          onClick={() => {
            navigate('/app/trash');
          }}
        >
          <TrashIcon />
        </IconButton>
      </Tooltip>

      <QuickNote />
    </div>
  );
}

export default SideBarBottom;