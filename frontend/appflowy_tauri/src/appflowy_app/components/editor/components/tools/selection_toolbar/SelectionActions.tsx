import React, { useMemo } from 'react';
import { useSlate } from 'slate-react';
import { Range } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { Paragraph } from '$app/components/editor/components/tools/selection_toolbar/actions/paragraph';
import { Heading } from '$app/components/editor/components/tools/selection_toolbar/actions/heading';
import { Divider } from '@mui/material';
import { Bold } from '$app/components/editor/components/tools/selection_toolbar/actions/bold';
import { Italic } from '$app/components/editor/components/tools/selection_toolbar/actions/italic';
import { Underline } from '$app/components/editor/components/tools/selection_toolbar/actions/underline';
import { StrikeThrough } from '$app/components/editor/components/tools/selection_toolbar/actions/strikethrough';
import { InlineCode } from '$app/components/editor/components/tools/selection_toolbar/actions/inline_code';
import { Formula } from '$app/components/editor/components/tools/selection_toolbar/actions/formula';
import { TodoList } from '$app/components/editor/components/tools/selection_toolbar/actions/todo_list';
import { Quote } from '$app/components/editor/components/tools/selection_toolbar/actions/quote';
import { ToggleList } from '$app/components/editor/components/tools/selection_toolbar/actions/toggle_list';
import { BulletedList } from '$app/components/editor/components/tools/selection_toolbar/actions/bulleted_list';
import { NumberedList } from '$app/components/editor/components/tools/selection_toolbar/actions/numbered_list';
import { Href } from '$app/components/editor/components/tools/selection_toolbar/actions/href';
import { Align } from '$app/components/editor/components/tools/selection_toolbar/actions/align';
import { Color } from '$app/components/editor/components/tools/selection_toolbar/actions/color';

function SelectionActions({
  storeSelection,
  restoreSelection,
}: {
  storeSelection: () => void;
  restoreSelection: () => void;
}) {
  const editor = useSlate();
  const isAcrossBlockSelection = useMemo(() => {
    if (!editor.selection) return false;
    const selection = editor.selection;
    const start = selection.anchor;
    const end = selection.focus;

    if (!start || !end) return false;

    if (!Range.isExpanded(selection)) return false;

    const startNode = CustomEditor.getBlock(editor, start);

    const endNode = CustomEditor.getBlock(editor, end);

    return Boolean(startNode && endNode && startNode[0].blockId !== endNode[0].blockId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor.selection, editor]);

  return (
    <div className={'flex w-fit flex-grow items-center gap-1'}>
      {!isAcrossBlockSelection && (
        <>
          <Paragraph />
          <Heading />
          <Divider className={'opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}
      <Bold />
      <Italic />
      <Underline />
      <StrikeThrough />
      <InlineCode />
      {!isAcrossBlockSelection && (
        <>
          <Formula />
          <Divider className={'opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}

      {!isAcrossBlockSelection && (
        <>
          <TodoList />
          <Quote />
          <ToggleList />
          <BulletedList />
          <NumberedList />
          <Divider className={'opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}
      {!isAcrossBlockSelection && <Href />}
      <Align />
      <Color onOpen={storeSelection} onClose={restoreSelection} />
    </div>
  );
}

export default SelectionActions;
