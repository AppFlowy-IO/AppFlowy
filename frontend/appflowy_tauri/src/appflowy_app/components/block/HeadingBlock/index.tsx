import React from 'react';
import { Block } from '$app/interfaces';
import TextBlock from '../TextBlock';

const fontSize: Record<string, string> = {
  1: 'mt-8 text-3xl',
  2: 'mt-6 text-2xl',
  3: 'mt-4 text-xl',
};
export default function HeadingBlock({ block }: { block: Block }) {
  return (
    <div className={`${fontSize[block.data.level]} font-semibold	`}>
      <TextBlock
        block={{
          ...block,
          children: [],
        }}
      />
    </div>
  );
}
