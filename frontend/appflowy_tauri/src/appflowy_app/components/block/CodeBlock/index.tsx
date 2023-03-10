import React from 'react';
import { Block } from '$app/interfaces';

export default function CodeBlock({ block }: { block: Block }) {
  return <div>{block.data.text}</div>;
}
