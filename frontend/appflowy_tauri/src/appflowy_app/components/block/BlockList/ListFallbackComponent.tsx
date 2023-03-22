import * as React from 'react';
import Typography, { TypographyProps } from '@mui/material/Typography';
import Skeleton from '@mui/material/Skeleton';
import Grid from '@mui/material/Grid';

const variants = ['h1', 'h3', 'body1', 'caption'] as readonly TypographyProps['variant'][];

export default function ListFallbackComponent() {
  return (
    <div id='appflowy-block-doc' className='doc-scroller-container flex h-[100%] flex-col items-center overflow-auto'>
      <div className='doc-content min-x-[0%] p-lg w-[900px] max-w-[100%]'>
        <div className='doc-title my-[50px] flex w-[100%] px-14 text-4xl font-bold'>
          <Typography className='w-[100%]' component='div' key={'h1'} variant={'h1'}>
            <Skeleton />
          </Typography>
        </div>
        <div className='doc-body px-14' style={{ height: '100vh' }}>
          <Grid container spacing={8}>
            <Grid item xs>
              {variants.map((variant) => (
                <Typography component='div' key={variant} variant={variant}>
                  <Skeleton />
                </Typography>
              ))}
            </Grid>
          </Grid>
        </div>
      </div>
    </div>
  );
}
