import React, { useMemo, useState } from 'react';
import { ImageNode } from '$app/application/document/document.types';
import { ReactComponent as CopyIcon } from '$app/assets/copy.svg';
import { ReactComponent as AlignLeftIcon } from '$app/assets/align-left.svg';
import { ReactComponent as AlignCenterIcon } from '$app/assets/align-center.svg';
import { ReactComponent as AlignRightIcon } from '$app/assets/align-right.svg';
import { ReactComponent as DeleteIcon } from '$app/assets/delete.svg';
import { useTranslation } from 'react-i18next';
import { IconButton } from '@mui/material';
import { notify } from '$app/components/_shared/notify';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import Popover from '@mui/material/Popover';
import Tooltip from '@mui/material/Tooltip';

enum ImageAction {
  Copy = 'copy',
  AlignLeft = 'left',
  AlignCenter = 'center',
  AlignRight = 'right',
  Delete = 'delete',
}

function ImageActions({ node }: { node: ImageNode }) {
  const { t } = useTranslation();
  const align = node.data.align;
  const editor = useSlateStatic();
  const [alignAnchorEl, setAlignAnchorEl] = useState<null | HTMLElement>(null);
  const alignOptions = useMemo(() => {
    return [
      {
        key: ImageAction.AlignLeft,
        Icon: AlignLeftIcon,
        onClick: () => {
          CustomEditor.setImageBlockData(editor, node, { align: 'left' });
          setAlignAnchorEl(null);
        },
      },
      {
        key: ImageAction.AlignCenter,
        Icon: AlignCenterIcon,
        onClick: () => {
          CustomEditor.setImageBlockData(editor, node, { align: 'center' });
          setAlignAnchorEl(null);
        },
      },
      {
        key: ImageAction.AlignRight,
        Icon: AlignRightIcon,
        onClick: () => {
          CustomEditor.setImageBlockData(editor, node, { align: 'right' });
          setAlignAnchorEl(null);
        },
      },
    ];
  }, [editor, node]);
  const options = useMemo(() => {
    return [
      {
        key: ImageAction.Copy,
        Icon: CopyIcon,
        tooltip: t('button.copyLink'),
        onClick: () => {
          if (!node.data.url) return;
          void navigator.clipboard.writeText(node.data.url);
          notify.success(t('message.copy.success'));
        },
      },
      (!align || align === 'left') && {
        key: ImageAction.AlignLeft,
        Icon: AlignLeftIcon,
        tooltip: t('button.align'),
        onClick: (e: React.MouseEvent<HTMLButtonElement>) => {
          setAlignAnchorEl(e.currentTarget);
        },
      },
      align === 'center' && {
        key: ImageAction.AlignCenter,
        Icon: AlignCenterIcon,
        tooltip: t('button.align'),
        onClick: (e: React.MouseEvent<HTMLButtonElement>) => {
          setAlignAnchorEl(e.currentTarget);
        },
      },
      align === 'right' && {
        key: ImageAction.AlignRight,
        Icon: AlignRightIcon,
        tooltip: t('button.align'),
        onClick: (e: React.MouseEvent<HTMLButtonElement>) => {
          setAlignAnchorEl(e.currentTarget);
        },
      },
      {
        key: ImageAction.Delete,
        Icon: DeleteIcon,
        tooltip: t('button.delete'),
        onClick: () => {
          CustomEditor.deleteNode(editor, node);
        },
      },
    ].filter(Boolean) as {
      key: ImageAction;
      Icon: React.FC<React.SVGProps<SVGSVGElement>>;
      tooltip: string;
      onClick: (e: React.MouseEvent<HTMLButtonElement>) => void;
    }[];
  }, [align, node, t, editor]);

  return (
    <div className={'absolute right-1 top-1 flex items-center justify-between rounded bg-bg-body shadow-lg'}>
      {options.map((option) => {
        const { key, Icon, tooltip, onClick } = option;

        return (
          <Tooltip disableInteractive={true} placement={'top'} title={tooltip} key={key}>
            <IconButton
              size={'small'}
              className={'bg-transparent p-2 text-icon-primary hover:text-fill-default'}
              onClick={onClick}
            >
              <Icon />
            </IconButton>
          </Tooltip>
        );
      })}
      {!!alignAnchorEl && (
        <Popover
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'left',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
          open={!!alignAnchorEl}
          anchorEl={alignAnchorEl}
          onClose={() => setAlignAnchorEl(null)}
        >
          {alignOptions.map((option) => {
            const { key, Icon, onClick } = option;

            return (
              <IconButton
                key={key}
                size={'small'}
                style={{
                  color: align === key ? 'var(--fill-default)' : undefined,
                }}
                className={'bg-transparent p-2 text-icon-primary hover:text-fill-default'}
                onClick={onClick}
              >
                <Icon />
              </IconButton>
            );
          })}
        </Popover>
      )}
    </div>
  );
}

export default ImageActions;
