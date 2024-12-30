import { useReadOnly } from '@/application/database-yjs';
import { CellProps, UrlCell as UrlCellType } from '@/application/database-yjs/cell.type';
import { notify } from '@/components/_shared/notify';
import { copyTextToClipboard } from '@/utils/copy';
import { openUrl, processUrl } from '@/utils/url';
import { IconButton, Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { ReactComponent as LinkSvg } from '@/assets/link.svg';
import { ReactComponent as CopySvg } from '@/assets/copy.svg';
import { useTranslation } from 'react-i18next';

export function UrlCell({ cell, style, placeholder }: CellProps<UrlCellType>) {
  const readOnly = useReadOnly();

  const isUrl = useMemo(() => (cell ? processUrl(cell.data) : false), [cell]);

  const [showActions, setShowActions] = React.useState(false);
  const className = useMemo(() => {
    const classList = ['select-text', 'w-fit', 'flex', 'w-full', 'items-center'];

    if (isUrl) {
      classList.push('text-content-blue-400', 'underline', 'cursor-pointer');
    } else {
      classList.push('cursor-text');
    }

    return classList.join(' ');
  }, [isUrl]);

  const { t } = useTranslation();

  if (!cell?.data)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;

  return (
    <div
      style={style}
      onMouseEnter={() => setShowActions(true)}
      onMouseLeave={() => setShowActions(false)}
      onClick={(e) => {
        if (!isUrl || !cell) return;
        if (readOnly) {
          e.stopPropagation();
          void openUrl(cell.data, '_blank');
        }
      }}
      className={className}
    >
      {cell?.data}
      {showActions && isUrl && (
        <div className={'absolute right-0 flex items-center gap-1 px-2'}>
          <Tooltip title={t('editor.openLink')} placement={'top'}>
            <IconButton
              sx={{
                border: '1px solid var(--line-divider)',
              }}
              onClick={(e) => {
                e.stopPropagation();
                void openUrl(cell.data, '_blank');
              }}
            >
              <LinkSvg />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('button.copyLink')} placement={'top'}>
            <IconButton
              sx={{
                border: '1px solid var(--line-divider)',
              }}
              onClick={async (e) => {
                e.stopPropagation();
                await copyTextToClipboard(cell.data);
                notify.success(t('grid.url.copy'));
              }}
            >
              <CopySvg />
            </IconButton>
          </Tooltip>
        </div>
      )}
    </div>
  );
}
