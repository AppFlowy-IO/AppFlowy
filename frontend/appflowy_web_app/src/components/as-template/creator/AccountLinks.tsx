import { TemplateCreator } from '@/application/template.type';
import { accountLinkIcon } from '@/components/as-template/icons';
import { TextField } from '@mui/material';
import React, { useState } from 'react';

const accountLinkTypes = ['youtube', 'twitter', 'instagram', 'facebook', 'linkedin', 'tiktok', 'website'] as const;

const placeholders = {
  youtube: 'https://www.youtube.com/channel/UC...',
  twitter: 'https://twitter.com/...',
  instagram: 'https://www.instagram.com/...',
  facebook: 'https://www.facebook.com/...',
  linkedin: 'https://www.linkedin.com/in/...',
  tiktok: 'https://www.tiktok.com/@...',
  website: 'https://',
};

function AccountLinks ({
  value,
  onChange,
}: {
  value: TemplateCreator['account_links'];
  onChange: (value: TemplateCreator['account_links']) => void;
}) {
  const [state, setState] = useState<TemplateCreator['account_links']>(value);

  return (
    <div className={'flex flex-wrap gap-4 h-fit'}>
      {accountLinkTypes.map((type, index) => (

        <TextField
          name={type}
          label={type}
          placeholder={placeholders[type]}
          InputProps={{
            startAdornment: (
              <div className={'flex items-center justify-center mr-2'}>
                {accountLinkIcon(type)}
              </div>
            ),
          }}

          key={index}
          value={state?.find((link) => link.link_type === type)?.url || ''}
          onChange={(e) => {
            const url = e.target.value;
            const newLinks = state?.filter((link) => link.link_type !== type) || [];

            if (url) {
              newLinks.push({ link_type: type, url });
            }

            setState(newLinks);
            onChange(newLinks);
          }}
        />
      ))}
    </div>
  );
}

export default AccountLinks;