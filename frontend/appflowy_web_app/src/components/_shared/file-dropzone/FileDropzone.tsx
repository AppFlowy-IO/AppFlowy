import React, { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  ReactComponent as Inbox,
} from '@/assets/inbox.svg';

interface FileDropzoneProps {
  onChange?: (files: File[]) => void;
  accept?: string;
  multiple?: boolean;
  disabled?: boolean;
}

function FileDropzone ({
  onChange,
  accept,
  multiple,
  disabled,
}: FileDropzoneProps) {
  const { t } = useTranslation();
  const [dragging, setDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFiles = (files: FileList) => {
    const fileArray = Array.from(files);

    if (onChange) {
      if (!multiple && fileArray.length > 1) {
        onChange(fileArray.slice(0, 1));
      } else {
        onChange(fileArray);

      }
    }
  };

  const handleDrop = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    event.stopPropagation();
    setDragging(false);

    if (event.dataTransfer.files && event.dataTransfer.files.length > 0) {
      handleFiles(event.dataTransfer.files);
      event.dataTransfer.clearData();
    }
  };

  const handleDragOver = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    event.stopPropagation();
    setDragging(true);
  };

  const handleDragLeave = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    event.stopPropagation();
    setDragging(false);
  };

  const handleClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files) {
      handleFiles(event.target.files);
      event.target.value = '';
    }
  };

  return (
    <div
      className={'w-full cursor-pointer hover:border-fill-active hover:border-2 hover:bg-bg-body h-[160px] rounded-xl border border-dashed border-line-border flex flex-col bg-bg-base'}
      onDrop={handleDrop}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onClick={handleClick}
      style={{
        borderColor: dragging ? 'var(--fill-active)' : undefined,
        backgroundColor: dragging ? 'var(--fill-active)' : undefined,
        pointerEvents: disabled ? 'none' : undefined,
        cursor: disabled ? 'not-allowed' : undefined,
      }}
    >
      <div className={'flex flex-col items-center justify-center gap-4 h-full'}>
        <Inbox className={'w-12 h-12 text-fill-default'} />
        <div className={'text-base text-text-title'}>
          {t('fileDropzone.dropFile')}
        </div>
      </div>
      <input
        type="file"
        disabled={disabled}
        ref={fileInputRef}
        style={{ display: 'none' }}
        accept={accept}
        multiple={multiple}
        onChange={handleFileChange}
      />
    </div>
  );

}

export default FileDropzone;