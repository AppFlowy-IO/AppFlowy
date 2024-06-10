import { fetchData } from '@/components/chat/fetch';
import CircularProgress from '@mui/material/CircularProgress';
import { SearchQuery } from './types';
import { FC, useRef, useState } from 'react';
import { ReactComponent as IconArrowRight } from '$icons/16x/arrow_right.svg';
import { ReactComponent as IconSearch } from '$icons/16x/search.svg';

interface SearchProps {
  onSearch: (searchResult: SearchQuery) => void;
  onAnswerUpdate: (answer: string) => void;
  onDone: (done: boolean) => void;
  done: boolean;
  apiKey: string;
}

export const Search: FC<SearchProps> = ({ apiKey, onSearch, onAnswerUpdate, onDone }) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const [query, setQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const handleSearch = async () => {
    if (!query) {
      alert('Please enter a query');
      return;
    }

    onDone(false);
    onSearch({ query });
    setLoading(true);

    await fetchData(apiKey, query, {
      onAnswerUpdate,
      onDone: (done) => {
        console.log('done', done);
        onDone(done);
        setLoading(false);
        setQuery('');
      },
    });
  };

  return (
    <>
      <div className='mx-auto flex h-full w-full flex-col items-center'>
        <div className='relative w-full'>
          <IconSearch className='text=[#D4D4D8] absolute top-3 left-1 h-6 w-10 rounded-full opacity-50 sm:left-3 sm:top-4 sm:h-8' />

          <input
            ref={inputRef}
            readOnly={loading}
            style={{
              cursor: loading ? 'not-allowed' : 'text',
              color: loading ? '#D4D4D8' : '#000',
            }}
            className='bg-body h-12 w-full rounded-full border border-line-border pr-12 pl-11 focus:border-zinc-800 focus:bg-content-blue-50 focus:outline-none focus:ring-2 focus:ring-zinc-800 sm:h-16 sm:py-2 sm:pr-16 sm:pl-16 sm:text-lg'
            type='text'
            placeholder='Ask anything...'
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                void handleSearch();
              }
            }}
          />

          <button
            className='absolute flex items-center justify-center  hover:cursor-pointer sm:right-3 sm:top-3 sm:h-10 sm:w-10'
            onClick={handleSearch}
            disabled={loading}
          >
            {loading ? (
              <CircularProgress size={24} />
            ) : (
              <IconArrowRight className='h-7 w-7 rounded-full bg-content-blue-400 p-1 text-content-on-fill hover:bg-content-blue-600' />
            )}
          </button>
        </div>
      </div>
    </>
  );
};
