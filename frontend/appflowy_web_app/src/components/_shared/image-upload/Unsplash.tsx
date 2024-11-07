import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { createApi } from 'unsplash-js';
import TextField from '@mui/material/TextField';
import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import debounce from 'lodash-es/debounce';
import { CircularProgress } from '@mui/material';
import { open } from '@tauri-apps/api/shell';

const unsplash = createApi({
  accessKey: '1WxD1JpMOUX86lZKKob4Ca0LMZPyO2rUmAgjpWm9Ids',
});

const SEARCH_DEBOUNCE_TIME = 500;

export function Unsplash ({ onDone, onEscape }: { onDone?: (value: string) => void; onEscape?: () => void }) {
  const { t } = useTranslation();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [photos, setPhotos] = useState<
    {
      thumb: string;
      regular: string;
      alt: string | null;
      id: string;
      user: {
        name: string;
        link: string;
      };
    }[]
  >([]);
  const [searchValue, setSearchValue] = useState('');

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;

    setSearchValue(value);
  }, []);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onEscape?.();
      }
    },
    [onEscape],
  );

  const debounceSearchPhotos = useMemo(() => {
    return debounce(async (searchValue: string) => {
      const request = searchValue
        ? unsplash.search.getPhotos({ query: searchValue ?? undefined, perPage: 32 })
        : unsplash.photos.list({ perPage: 32 });

      setError('');
      setLoading(true);
      await request.then((result) => {
        if (result.errors) {
          setError(result.errors[0]);
        } else {
          setPhotos(
            result.response.results.map((photo) => ({
              id: photo.id,
              thumb: photo.urls.thumb,
              regular: photo.urls.regular,
              alt: photo.alt_description,
              user: {
                name: photo.user.name,
                link: photo.user.links.html,
              },
            })),
          );
        }

        setLoading(false);
      });
    }, SEARCH_DEBOUNCE_TIME);
  }, []);

  useEffect(() => {
    void debounceSearchPhotos(searchValue);
    return () => {
      debounceSearchPhotos.cancel();
    };
  }, [debounceSearchPhotos, searchValue]);

  return (
    <div
      tabIndex={0}
      onKeyDown={handleKeyDown}
      className={'flex min-h-[600px] flex-col gap-4 px-4 pb-4'}
    >
      <TextField
        autoFocus
        onKeyDown={handleKeyDown}
        size={'small'}
        spellCheck={false}
        onChange={handleChange}
        value={searchValue}
        placeholder={t('document.imageBlock.searchForAnImage')}
        fullWidth
      />

      {loading ? (
        <div className={'flex h-[120px] w-full items-center justify-center gap-2 text-xs'}>
          <CircularProgress size={24} />
          <div className={'text-xs text-text-caption'}>{t('editor.loading')}</div>
        </div>
      ) : error ? (
        <Typography className={'flex h-[120px] w-full items-center justify-center gap-2 text-xs text-function-error'}>
          {error}
        </Typography>
      ) : (
        <div className={'flex flex-col gap-4'}>
          {photos.length > 0 ? (
            <>
              <div
                className={`
        grid 
        gap-4 
        w-full
        grid-cols-1
        sm:grid-cols-2 
        md:grid-cols-3 
        lg:grid-cols-4
        auto-rows-fr
      `}
              >
                {photos.map((photo) => (
                  <div
                    key={photo.id}
                    className={'flex flex-col gap-2'}
                  >
                    <div className={'relative pt-[56.25%]'}>
                      <img
                        onClick={() => {
                          onDone?.(photo.regular);
                        }}
                        src={photo.thumb}
                        alt={photo.alt ?? ''}
                        className={`
                  absolute top-0 left-0 
                  w-full h-full 
                  rounded object-cover 
                  cursor-pointer
                  hover:opacity-80 
                  transition-opacity
                `}
                      />
                    </div>
                    <div className={'w-full truncate text-xs text-text-caption'}>
                      by{' '}
                      <span
                        onClick={() => {
                          void open(photo.user.link);
                        }}
                        className={'underline hover:text-function-info'}
                      >
                {photo.user.name}
              </span>
                    </div>
                  </div>
                ))}
              </div>
              <Typography className={'w-full text-center text-xs text-text-caption'}>
                {t('findAndReplace.searchMore')}
              </Typography>
            </>
          ) : (
            <Typography className={'flex h-[120px] w-full items-center justify-center gap-2 text-xs text-text-caption'}>
              {t('findAndReplace.noResult')}
            </Typography>
          )}
        </div>
      )}
    </div>
  );
}
