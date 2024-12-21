import { Mention, MentionType } from '@/application/types';
import { useLeafSelected } from '@/components/editor/components/leaf/leaf.hooks';
import MentionDate from '@/components/editor/components/leaf/mention/MentionDate';
import MentionPage from '@/components/editor/components/leaf/mention/MentionPage';
import React, { useMemo } from 'react';
import { Element, Text } from 'slate';
import { useReadOnly, useSlateStatic } from 'slate-react';

export function MentionLeaf({ mention, text, children }: {
  mention: Mention;
  text: Text;
  children: React.ReactNode;
}) {
  const editor = useSlateStatic();
  const readonly = useReadOnly() || editor.isElementReadOnly(text as unknown as Element);
  const { type, date, page_id, reminder_id, reminder_option, block_id } = mention;

  const reminder = useMemo(() => {
    return reminder_id ? { id: reminder_id ?? '', option: reminder_option ?? '' } : undefined;
  }, [reminder_id, reminder_option]);

  const content = useMemo(() => {
    if ([MentionType.PageRef, MentionType.childPage].includes(type) && page_id) {
      return <MentionPage
        text={text}
        type={type}
        pageId={page_id}
        blockId={block_id}
      />;
    }

    if (type === MentionType.Date && date) {
      return <MentionDate
        date={date}
        reminder={reminder}
      />;
    }
  }, [text, date, page_id, reminder, type, block_id]);

  // check if the mention is selected
  const { isSelected, select, isCursorBefore } = useLeafSelected(text);
  const className = useMemo(() => {
    const classList = ['w-fit mention', 'relative', 'rounded', 'py-0.5  px-1'];

    if (readonly) classList.push('cursor-default');
    else if (type !== MentionType.Date) classList.push('cursor-pointer');

    if (isSelected && type !== MentionType.Date) classList.push('selected');
    return classList.join(' ');
  }, [type, readonly, isSelected]);

  return <>
    {isCursorBefore && !isSelected && <span data-slate-string="true">{
      `\u200B`
    }</span>}
    <span
      className={'absolute right-0 !text-transparent overflow-hidden'}
    >
      {children}
    </span>

    <span
      onClick={select}
      contentEditable={false}
      className={className}
    >
    {content}

  </span>

  </>;
}

export default MentionLeaf;
