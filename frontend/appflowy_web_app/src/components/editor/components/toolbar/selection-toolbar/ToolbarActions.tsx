import { YjsEditor } from '@/application/slate-yjs';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType } from '@/application/types';
import Align from '@/components/editor/components/toolbar/selection-toolbar/actions/Align';
import Bold from '@/components/editor/components/toolbar/selection-toolbar/actions/Bold';
import BulletedList from '@/components/editor/components/toolbar/selection-toolbar/actions/BulletedList';
import Href from '@/components/editor/components/toolbar/selection-toolbar/actions/Href';
import Color from '@/components/editor/components/toolbar/selection-toolbar/actions/Color';
import Formula from '@/components/editor/components/toolbar/selection-toolbar/actions/Formula';
import Heading from '@/components/editor/components/toolbar/selection-toolbar/actions/Heading';
import InlineCode from '@/components/editor/components/toolbar/selection-toolbar/actions/InlineCode';
import Italic from '@/components/editor/components/toolbar/selection-toolbar/actions/Italic';
import NumberedList from '@/components/editor/components/toolbar/selection-toolbar/actions/NumberedList';
import Quote from '@/components/editor/components/toolbar/selection-toolbar/actions/Quote';
import StrikeThrough from '@/components/editor/components/toolbar/selection-toolbar/actions/StrikeThrough';
import Underline from '@/components/editor/components/toolbar/selection-toolbar/actions/Underline';
import {
  useSelectionToolbarContext,
} from '@/components/editor/components/toolbar/selection-toolbar/SelectionToolbar.hooks';
import { Divider } from '@mui/material';
import { Editor, Element } from 'slate';
import Paragraph from './actions/Paragraph';
import React, { useMemo } from 'react';
import { useSlate } from 'slate-react';

function ToolbarActions() {
  const editor = useSlate() as YjsEditor;
  const selection = editor.selection;
  const start = useMemo(() => selection ? editor.start(selection) : null, [editor, selection]);
  const end = useMemo(() => selection ? editor.end(selection) : null, [editor, selection]);
  const startBlock = useMemo(() => {
    if (!start) return null;
    try {
      return getBlockEntry(editor, start);
    } catch (e) {
      return null;
    }
  }, [editor, start]);
  const endBlock = useMemo(() => {
    if (!end) return null;
    try {
      return getBlockEntry(editor, end);
    } catch (e) {
      return null;
    }
  }, [editor, end]);

  const isAcrossBlock = useMemo(() => {
    return startBlock?.[0].blockId !== endBlock?.[0].blockId;
  }, [endBlock, startBlock]);

  const isCodeBlock = useMemo(() => {
    if (!start || !end) return false;
    const range = { anchor: start, focus: end };

    const [codeBlock] = editor.nodes({
      at: range,
      match: n => !Editor.isEditor(n) && Element.isElement(n) && n.type === BlockType.CodeBlock,
    });

    return !!codeBlock;
  }, [editor, end, start]);

  const groupTwo = <>
    <Underline/>
    <Bold/>
    <Italic/>
    <StrikeThrough/>
  </>;

  const groupOne = <>
    <Paragraph/>
    <Heading/>
    <Divider
      className={'my-1.5 bg-line-on-toolbar'}
      orientation={'vertical'}
      flexItem={true}
    />
  </>;

  const groupThree = <>
    <Divider
      className={'my-1.5 bg-line-on-toolbar'}
      orientation={'vertical'}
      flexItem={true}
    />
    <Quote/>
    <BulletedList/>
    <NumberedList/>
    <Divider
      className={'my-1.5 bg-line-on-toolbar'}
      orientation={'vertical'}
      flexItem={true}
    />
    <Href/>
  </>;
  const {
    visible: toolbarVisible,
  } = useSelectionToolbarContext();

  const groupFour = <><Align enabled={toolbarVisible}/></>;

  return (
    <div
      className={'flex w-fit flex-grow items-center gap-1'}
    >
      {
        !isAcrossBlock && !isCodeBlock && groupOne
      }
      {groupTwo}
      {!isCodeBlock && <InlineCode/>}
      {!isCodeBlock && !isAcrossBlock && <Formula/>}
      {
        !isAcrossBlock && !isCodeBlock && groupThree
      }
      {!isCodeBlock && groupFour}
      <Color/>
    </div>
  );
}

export default ToolbarActions;