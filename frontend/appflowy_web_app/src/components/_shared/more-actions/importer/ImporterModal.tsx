import { NormalModal } from '@/components/_shared/modals/NormalModal';
import { ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { AFConfigContext } from '@/components/main/app.hooks';
import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as NotionIcon } from '@/assets/notion.svg';

export function ImportModal ({
  open,
  onClose,
}: {
  open,
  onClose,
}) {
  const { t } = useTranslation();
  const service = useContext(AFConfigContext)?.service;
  const [value, setValue] = React.useState<string>('notion');

  return (
    <NormalModal
      onCancel={onClose}
      title={t('web.import')}
      open={open}
      onClose={onClose}
      classes={{ container: 'items-start max-md:mt-auto max-md:items-center mt-[10%] ' }}
      okButtonProps={{
        className: 'hidden',
      }}
      cancelButtonProps={{
        className: 'hidden',
      }}
    >
      <ViewTabs
        className={'border-b border-line-divider'}
        onChange={(_e, newValue) => setValue(newValue)}
        value={value}
      >
        <ViewTab
          className={'flex items-center flex-row justify-center gap-1.5'}
          value={'notion'}
          label={t('web.importNotion')}
          icon={<NotionIcon />}
        />

      </ViewTabs>
      <div className={'p-2'}>
        <TabPanel
          className={'min-w-[360px] max-sm:min-w-[80vw]'}
          index={'notion'}
          value={value}
        >
        </TabPanel>
      </div>
    </NormalModal>
  );
}

export default ImportModal;