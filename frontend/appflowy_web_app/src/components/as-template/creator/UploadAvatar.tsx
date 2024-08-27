import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { useService } from '@/components/app/app.hooks';
import { CircularProgress, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as LinkIcon } from '@/assets/link.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as CheckIcon } from '@/assets/check_circle.svg';

function UploadAvatar ({
  onChange,
}: {
  onChange: (url: string) => void;
}) {
  const { t } = useTranslation();

  const [file, setFile] = React.useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = React.useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const service = useService();
  const [hovered, setHovered] = React.useState(false);

  const uploadStatusText = useMemo(() => {
    switch (uploadStatus) {
      case 'success':
        return t('fileDropzone.uploadSuccess');
      case 'error':
        return t('fileDropzone.uploadFailed');
      default:
        return t('fileDropzone.uploading');
    }
  }, [uploadStatus, t]);
  const handleUpload = useCallback(async (file: File) => {
    setUploadStatus('loading');

    try {
      const url = await service?.uploadFileToCDN(file);

      if (!url) throw new Error('Failed to upload file');
      onChange(url);
      setUploadStatus('success');
    } catch (error) {
      onChange('');
      setUploadStatus('error');
    }

  }, [service, onChange]);

  return (
    <>
      <FileDropzone
        accept={'image/*'}
        onChange={files => {
          setFile(files[0]);
          void handleUpload(files[0]);
        }}
      />
      {file && (
        <div className={'flex gap-2 items-center'}>
          <div className={'w-[80px] aspect-square rounded-xl border border-line-divider'}
          >
            <img
              src={URL.createObjectURL(file)}
              alt={file.name}
              className={'w-full h-full'}
            />
          </div>

          <div
            className={'flex items-center gap-2 overflow-hidden w-full hover:bg-fill-list-hover rounded-lg p-1'}
            onMouseLeave={() => setHovered(false)}
            onMouseEnter={() => setHovered(true)}
            style={{
              color: uploadStatus === 'error' ? 'var(--function-error)' : undefined,
            }}
          >
            {uploadStatus === 'loading' ? <CircularProgress size={20} /> : <LinkIcon className={'w-5 h-5'} />}

            <Tooltip title={uploadStatusText} placement={'bottom-start'}>
              <div className={'flex-1 truncate cursor-pointer'}>{file.name}</div>
            </Tooltip>
            {
              uploadStatus === 'success' && !hovered && <CheckIcon className={'w-5 h-5 text-function-success'} />
            }
            {hovered && <Tooltip title={t('button.remove')} arrow>
              <IconButton
                onClick={() => {
                  setFile(null);
                  onChange('');
                }}
                size={'small'}
                color={'error'}
              >
                <DeleteIcon className={'w-5 h-5'} />
              </IconButton>
            </Tooltip>}

          </div>
        </div>
      )}
    </>
  );
}

export default UploadAvatar;