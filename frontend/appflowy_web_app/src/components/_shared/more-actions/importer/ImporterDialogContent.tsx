import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { notify } from '@/components/_shared/notify';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { AFConfigContext } from '@/components/main/app.hooks';
import LinearProgress from '@mui/material/LinearProgress';
import React, { useCallback, useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as NotionIcon } from '@/assets/notion.svg';

function ImporterDialogContent ({
  source,
  onSuccess,
}: {
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
    if (!service) return;
    try {
      await service.importFile(file, setProgress);
      onSuccess();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (e: any) {
      notify.error(e.message);
      setIsError(true);
    }
  }, [onSuccess, service]);

  return (
    <div className={'flex flex-col gap-8'}>
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
      <div className={'p-2 pb-0'}>
        <TabPanel
          className={'min-w-[480px] max-w-full overflow-hidden max-sm:w-full flex flex-col gap-2 max-sm:min-w-[80vw]'}
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
            placeholder={t('web.dropNotionFile')}
          />
          {progress > 0 && <LinearProgress
            variant="determinate"
            color={isError ? 'error' : progress === 1 ? 'success' : 'primary'}
            value={progress * 100}
          />}
        </TabPanel>
      </div>
    </div>
  );
}

export default ImporterDialogContent;