import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { TAB_KEYS, TabPanel } from './TabPanel';
import { Box, Button, Tab, Tabs, TextField } from '@mui/material';
import UploadImage from './UploadImage';

interface Props {
  onSubmitUrl: (url: string) => void;
  url?: string;
}

function ImageEdit({ onSubmitUrl, url }: Props) {
  const { t } = useTranslation();
  const [linkVal, setLinkVal] = useState<string>(url || '');
  const [tabKey, setTabKey] = useState<TAB_KEYS>(TAB_KEYS.UPLOAD);
  const handleChange = useCallback((_: React.SyntheticEvent, newValue: TAB_KEYS) => {
    setTabKey(newValue);
  }, []);

  return (
    <div className={'h-full w-full'}>
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabKey} onChange={handleChange}>
          <Tab label={t('document.imageBlock.upload.label')} value={TAB_KEYS.UPLOAD} />

          <Tab label={t('document.imageBlock.url.label')} value={TAB_KEYS.LINK} />
        </Tabs>
      </Box>
      <TabPanel value={tabKey} index={TAB_KEYS.UPLOAD}>
        <UploadImage onChange={onSubmitUrl} />
      </TabPanel>

      <TabPanel className={'flex flex-col p-3'} value={tabKey} index={TAB_KEYS.LINK}>
        <TextField
          value={linkVal}
          onChange={(e) => setLinkVal(e.target.value)}
          variant='outlined'
          label={t('document.imageBlock.url.label')}
          autoFocus={true}
          style={{
            marginBottom: '10px',
          }}
          placeholder={t('document.imageBlock.url.placeholder')}
        />
        <Button onClick={() => onSubmitUrl(linkVal)} variant='contained'>
          {t('button.upload')}
        </Button>
      </TabPanel>
    </div>
  );
}

export default ImageEdit;
