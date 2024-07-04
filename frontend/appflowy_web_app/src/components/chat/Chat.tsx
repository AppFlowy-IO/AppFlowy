import { AFScroller } from '@/components/_shared/scroller';
import { SearchQuery } from '@/components/chat/types';
import { Tooltip } from '@mui/material';
import React, { useEffect, useRef, useState } from 'react';
import { Answer } from './Answer';
import { Search } from './Search';
import { ReactComponent as ReloadICON } from '$icons/16x/reload.svg';
import './markdown.scss';

export function Chat() {
  const [searchQuery, setSearchQuery] = useState<SearchQuery>({ query: '' });
  const [answer, setAnswer] = useState<string>('');
  const [apiKeyValue, setApiKeyValue] = useState<string>('');
  const [apiKey, setApiKey] = useState<string>(() => {
    const key = localStorage.getItem('openai-api-key');

    return key ? key : '';
  });
  const conversationRef = useRef<
    {
      query: string;
      answer: string;
    }[]
  >([]);

  const [done, setDone] = useState<boolean>(false);

  useEffect(() => {
    if (!done) {
      return;
    }

    if (!answer) {
      return;
    }

    if (conversationRef.current.length === 0) {
      conversationRef.current = [
        {
          query: searchQuery.query,
          answer,
        },
      ];
    } else {
      conversationRef.current.push({
        query: searchQuery.query,
        answer,
      });
    }

    setSearchQuery({ query: '' });
    setAnswer('');
  }, [answer, done, searchQuery.query]);
  return (
    <div className={'flex h-screen w-screen flex-col items-center justify-center gap-8 py-10'}>
      <div className={'flex h-[48px] w-full items-center justify-end gap-2 px-10'}>
        <Tooltip title={'Clear all conversation'}>
          <button>
            <ReloadICON
              className={'h-6 w-6 cursor-pointer hover:text-content-blue-400'}
              onClick={() => {
                conversationRef.current = [];
                setAnswer('');
                setSearchQuery({ query: '' });
                setDone(false);
                setApiKey(localStorage.getItem('openai-api-key') || '');
              }}
            />
          </button>
        </Tooltip>
      </div>
      <AFScroller className={'flex flex-1 flex-col items-center gap-4'}>
        {conversationRef.current?.map((item, index) => (
          <Answer key={index} query={item.query} answer={item.answer} done={done} />
        ))}
        {answer && <Answer query={searchQuery.query} answer={answer} done={done} />}
      </AFScroller>
      <div className={'h-[64px] w-[80%]'}>
        {apiKey ? (
          <Search
            apiKey={apiKey}
            onSearch={setSearchQuery}
            onAnswerUpdate={(value) => {
              setAnswer((prev) => prev + value);
            }}
            done={done}
            onDone={setDone}
          />
        ) : (
          <div className={'flex items-center justify-center gap-4'}>
            <input
              placeholder={'Enter your API Key'}
              value={apiKeyValue}
              onChange={(e) => setApiKeyValue(e.target.value)}
              className={'h-12 w-full rounded-md border border-gray-300 px-4'}
            />
            <button
              onClick={() => {
                setApiKey(apiKeyValue);
                localStorage.setItem('openai-api-key', apiKeyValue);
                setApiKeyValue('');
              }}
              className={'h-12 w-[100px] rounded-md bg-blue-400 text-white'}
            >
              Save
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

export default Chat;
