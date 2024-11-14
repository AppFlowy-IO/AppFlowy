import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { Origins, Popover } from '@/components/_shared/popover';
import { OutlineNode } from '@/components/editor/editor.type';
import { Button, Divider, IconButton } from '@mui/material';
import React, { useCallback, useRef } from 'react';
import { ReactComponent as HashtagIcon } from '@/assets/sign-hashtag.svg';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';

const origins: Origins = {
  anchorOrigin: {
    vertical: 'top',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: -16,
  },
};

function Depth ({
  node,
}: {
  node: OutlineNode
}) {
  const [open, setOpen] = React.useState(false);
  const ref = useRef<HTMLButtonElement>(null);
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
  const blockId = node.blockId;
  const [originalDepth, setOriginalDepth] = React.useState<number>(node.data.depth || 1);

  const handleDepthChange = useCallback((depth: number) => {
    if (depth === originalDepth) return;
    CustomEditor.setBlockData(editor, blockId, {
      depth,
    });
    setOriginalDepth(depth);
  }, [blockId, editor, originalDepth]);

  return (
    <>
      <Divider />
      <Button
        ref={ref}
        startIcon={<HashtagIcon />}
        size={'small'}
        color={'inherit'}
        className={'justify-start'}
        onClick={() => {
          setOpen(true);
        }}
      >
        {t('document.plugins.optionAction.depth')}
      </Button>
      <Popover
        open={open}
        anchorEl={ref.current}
        onClose={() => setOpen(false)}
        {...origins}
      >
        <div className={'flex p-2 flex-col gap-2'}>
          {
            ['H1', 'H2', 'H3', 'H4', 'H5', 'H6'].map((depth) => {
              return (
                <IconButton
                  key={depth}
                  className={`${originalDepth === Number(depth[1]) ? '!text-fill-default' : ''} text-text-title text-sm p-1 px-2`}
                  onClick={() => {
                    handleDepthChange(Number(depth[1]));
                    setOpen(false);
                  }}
                >
                  {depth}
                </IconButton>
              );
            })
          }
        </div>

      </Popover>
    </>
  );
}

export default Depth;