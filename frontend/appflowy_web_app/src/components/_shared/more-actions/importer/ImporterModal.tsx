import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { notify } from '@/components/_shared/notify';
import { ViewTab, ViewTabs, TabPanel } from '@/components/_shared/tabs/ViewTabs';
import { AFConfigContext } from '@/components/main/app.hooks';
import LinearProgress from '@mui/material/LinearProgress';
import React, { useCallback, useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as NotionIcon } from '@/assets/notion.svg';
import { NormalModal } from '@/components/_shared/modal';
import { ReactComponent as ImportIcon } from '@/assets/import.svg';

export function ImporterModal ({
  open,
  onClose,
  source,
  onSuccess,
}: {
  open: boolean,
  onClose: () => void,
  source?: string,
  onSuccess: () => void,
}) {
  const { t } = useTranslation();
  const service = useContext(AFConfigContext)?.service;
  const [value, setValue] = React.useState<string>(source || 'notion');
  const [progress, setProgress] = React.useState<number>(0);
  const [isError, setIsError] = React.useState<boolean>(false);

  const handleUpload = useCallback(async (file: File) => {
    setIsError(false);
    try {
      await service?.importFile(file, setProgress);
      onSuccess();
    } catch (e) {
      notify.error(t('web.importFailed'));
      setIsError(true);
    }
  }, [onSuccess, service, t]);

  return (
    <NormalModal
      onCancel={onClose}
      title={
        <div className={'flex items-center gap-2 justify-center font-semibold'}>
          <ImportIcon className={'w-6 h-6'} />
          {t('web.import')}
        </div>
      }
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
          icon={<NotionIcon className={'w-4 h-4 mb-0'} />}
        />

      </ViewTabs>
      <div className={'p-2 pt-8 pb-0'}>
        <TabPanel
          className={'min-w-[480px] flex flex-col gap-2 max-sm:min-w-[80vw]'}
          index={'notion'}
          value={value}
        >
          <FileDropzone
            accept={'.zip,application/zip,application/x-zip,application/x-zip-compressed'}
            multiple={false}
            onChange={files => {
              if (!files.length) return;
              void handleUpload(files[0]);
            }}
            disabled={!isError && progress < 1 && progress > 0}
          />
          {progress > 0 && <LinearProgress
            variant="determinate"
            color={isError ? 'error' : progress === 1 ? 'success' : 'primary'}
            value={progress * 100}
          />}
        </TabPanel>
      </div>
    </NormalModal>
  );
}

export default ImporterModal;