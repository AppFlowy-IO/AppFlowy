import React from 'react';
export enum TAB_KEYS {
  UPLOAD = 'upload',
  LINK = 'link',
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: TAB_KEYS;
  value: TAB_KEYS;
}

export function TabPanel(props: TabPanelProps & React.HTMLAttributes<HTMLDivElement>) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role='tabpanel'
      hidden={value !== index}
      id={`image-tabpanel-${index}`}
      aria-labelledby={`image-tab-${index}`}
      {...other}
    >
      {value === index && children}
    </div>
  );
}
