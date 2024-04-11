import React from 'react';

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
import { Href, LinkActions } from '$app/components/editor/components/tools/selection_toolbar/actions/href';
import { Align } from '$app/components/editor/components/tools/selection_toolbar/actions/align';
import { Color } from '$app/components/editor/components/tools/selection_toolbar/actions/color';

function SelectionActions({
  isAcrossBlocks,
  storeSelection,
  restoreSelection,
  isIncludeRoot,
}: {
  storeSelection: () => void;
  restoreSelection: () => void;
  isAcrossBlocks: boolean;
  visible: boolean;
  isIncludeRoot: boolean;
}) {
  if (isIncludeRoot) return null;
  return (
    <div className={'flex w-fit flex-grow items-center gap-1'}>
      {!isAcrossBlocks && (
        <>
          <Paragraph />
          <Heading />
          <Divider className={'my-1.5 bg-line-on-toolbar opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}
      <Bold />
      <Italic />
      <Underline />
      <StrikeThrough />
      <InlineCode />
      {!isAcrossBlocks && (
        <>
          <Formula />
          <Divider className={'my-1.5 bg-line-on-toolbar opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}

      {!isAcrossBlocks && (
        <>
          <TodoList />
          <Quote />
          <ToggleList />
          <BulletedList />
          <NumberedList />
          <Divider className={'my-1.5 bg-line-on-toolbar opacity-40'} orientation={'vertical'} flexItem={true} />
        </>
      )}
      {!isAcrossBlocks && <Href />}
      <Align />
      <Color onClose={restoreSelection} onOpen={storeSelection} />
      <LinkActions />
    </div>
  );
}

export default SelectionActions;
