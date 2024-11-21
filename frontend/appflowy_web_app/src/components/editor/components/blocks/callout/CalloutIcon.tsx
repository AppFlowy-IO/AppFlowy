import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { ViewIconType } from '@/application/types';
import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import { CalloutNode } from '@/components/editor/editor.type';
import React, { useCallback, useRef } from 'react';
import { useReadOnly, useSlateStatic } from 'slate-react';

function CalloutIcon ({ block: node, className }: { block: CalloutNode; className: string }) {
  const ref = useRef<HTMLButtonElement>(null);
  const readOnly = useReadOnly();
  const editor = useSlateStatic();
  const blockId = node.blockId;

  const [open, setOpen] = React.useState(false);
  const handleChangeIcon = useCallback((icon: { ty: ViewIconType, value: string }) => {
    setOpen(false);

    CustomEditor.setBlockData(editor as YjsEditor, blockId, { icon: icon.value });
  }, [editor, blockId]);

  const handleRemoveIcon = useCallback(() => {
    setOpen(false);
    CustomEditor.setBlockData(editor as YjsEditor, blockId, { icon: null });
  }, [blockId, editor]);

  return (
    <>
      <span
        onClick={() => {
          if (readOnly) return;
          setOpen(true);
        }}
        contentEditable={false}
        ref={ref}
        className={`icon ${className} ${readOnly ? '' : 'cursor-pointer'} flex h-6 w-6 items-center`}
      >
        {node.data.icon || `📌`}
      </span>
      <ChangeIconPopover
        open={open}
        anchorEl={ref.current}
        onClose={() => {
          setOpen(false);
        }}
        defaultType={'emoji'}
        iconEnabled={false}
        onSelectIcon={handleChangeIcon}
        removeIcon={handleRemoveIcon}
        popoverProps={{
          sx: {
            '& .MuiPopover-paper': {
              margin: '16px 0',
            },
          },
        }}
      />
    </>
  );
}

export default React.memo(CalloutIcon);
