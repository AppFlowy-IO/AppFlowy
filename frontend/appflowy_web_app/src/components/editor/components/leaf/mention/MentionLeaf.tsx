import { Mention, MentionType } from '@/application/types';
import { useLeafSelected } from '@/components/editor/components/leaf/leaf.hooks';
import MentionDate from '@/components/editor/components/leaf/mention/MentionDate';
import MentionPage from '@/components/editor/components/leaf/mention/MentionPage';
import { useMemo } from 'react';
import { Text } from 'slate';
import { useReadOnly } from 'slate-react';

export function MentionLeaf ({ mention, text }: {
  mention: Mention;
  text: Text;
}) {
  const readonly = useReadOnly();
  const { type, date, page_id, reminder_id, reminder_option, block_id } = mention;

  const reminder = useMemo(() => {
    return reminder_id ? { id: reminder_id ?? '', option: reminder_option ?? '' } : undefined;
  }, [reminder_id, reminder_option]);

  const content = useMemo(() => {
    if ([MentionType.PageRef, MentionType.childPage].includes(type) && page_id) {
      return <MentionPage
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
  }, [date, page_id, reminder, type, block_id]);

  // check if the mention is selected
  const { isSelected, select, isCursorAfter, isCursorBefore } = useLeafSelected(text);
  const className = useMemo(() => {
    const classList = ['w-fit mention', 'relative', 'rounded', 'py-0.5'];

    if (readonly) classList.push('cursor-default');
    else classList.push('cursor-pointer');

    if (isSelected) classList.push('selected');
    if (isCursorAfter) classList.push('cursor-after');
    if (isCursorBefore) classList.push('cursor-before');
    return classList.join(' ');
  }, [readonly, isSelected, isCursorAfter, isCursorBefore]);

  return <span
    onClick={select}
    contentEditable={false}
    className={className}
  >
    {content}
  </span>;
}

export default MentionLeaf;
