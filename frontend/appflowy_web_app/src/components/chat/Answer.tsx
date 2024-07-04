import { FC, useMemo } from 'react';
import DOMPurify from 'dompurify';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
import markdownit from 'markdown-it';

interface AnswerProps {
  query: string;
  answer: string;
  done: boolean;
}

export const Answer: FC<AnswerProps> = ({ query, answer }) => {
  const md = useMemo(() => markdownit(), []);

  return (
    <div className='max-w-[800px] px-8 pb-8'>
      <div className='text-2xl font-bold text-text-caption'>{`Q: ${query} `}</div>

      <div className='border-b border-line-border pb-8'>
        <div
          className='markdown-content mt-2 h-fit'
          dangerouslySetInnerHTML={{
            __html: DOMPurify.sanitize(md.render(answer)),
          }}
        />
      </div>
    </div>
  );
};
