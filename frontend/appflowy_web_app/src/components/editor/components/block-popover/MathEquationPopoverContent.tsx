import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { MathEquationBlockData } from '@/application/types';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { MathEquationNode } from '@/components/editor/editor.type';
import { Button, TextField } from '@mui/material';
import React, { useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { NodeEntry } from 'slate';
import { useSlateStatic } from 'slate-react';

function MathEquationPopoverContent ({
  blockId,
}: {
  blockId: string
}) {
  const {
    close,
  } = usePopoverContext();

  const editor = useSlateStatic() as YjsEditor;
  const [formula, setFormula] = React.useState('');
  const { t } = useTranslation();
  const handleSave = useCallback((formula: string) => {
    CustomEditor.setBlockData(editor, blockId, {
      formula,
    } as MathEquationBlockData);
    close();
  }, [blockId, close, editor]);

  useEffect(() => {
    const entry = findSlateEntryByBlockId(editor, blockId) as NodeEntry<MathEquationNode>;

    if (!entry) {
      console.error('Block not found');
      return;
    }

    const [node] = entry;

    setFormula(node.data?.formula || '');
  }, [blockId, editor]);

  return (
    <div className={'flex flex-col p-2 gap-2  w-[560px] max-w-[964px]'}>
      <TextField
        rows={4}
        multiline
        fullWidth
        value={formula}
        onChange={(e) => setFormula(e.target.value)}
        placeholder={`E.g. x^2 + y^2 = z^2`}
        autoComplete={'off'}
        spellCheck={false}
        onKeyDown={e => {
          if (e.key === 'Enter') {
            e.preventDefault();
            handleSave(formula);
          }
        }}
      />
      <div className={'flex justify-end gap-2'}>
        <Button
          size={'small'}
          variant={'outlined'}
          color={'inherit'}
          onClick={() => close()}
        >{t('button.cancel')}</Button>
        <Button
          size={'small'}
          variant={'contained'}
          color={'primary'}
          onClick={() => handleSave(formula)}
        >{t('button.save')}</Button>
      </div>
    </div>
  );
}

export default MathEquationPopoverContent;