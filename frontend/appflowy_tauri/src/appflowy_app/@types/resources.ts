// i18n.json is generated from pnpm tauri:dev
// This file just used to make typescript happy
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import translation from './i18n.json';

const resources = {
  translation: {
    ...translation,
    'tooltip.addBlockBelow': 'Add a block below',
    'toolbar.addLink': 'Add Link',
    'toolbar.link': 'Link',
    'document.textBlock.placeholder': "Type '/' to insert a block",
    'document.title.placeholder': 'Unititled',
    search: 'Search',
    'search.placeholder.actions': 'Search actions...',
    'document.imageBlock.placeholder': 'Click to add image',
    'document.imageBlock.upload': 'UploadImage',
    'document.imageBlock.url': 'Image URL',
    'document.imageBlock.url.placeholder': 'Please enter the URL of the image',
    'button.delete': 'Delete',
    'button.edit': 'Edit',
    'button.done': 'Done',
    'document.codeBlock.language.label': 'Language',
    'document.inlineLink.placeholder': 'Enter a URL',
    'document.inlineLink.url': 'URL',
    'document.inlineLink.title': 'Link Title',
    'message.copy.success': 'Copied!',
    'message.copy.fail': 'Unable to copy',
    'image.tip': 'The maximum file size is 5MB. Supported formats: JPG, PNG, GIF, SVG.',
    'image.upload.error': 'Image upload failed',
    'image.size.error': 'Image size is too large',
    'image.type.error': 'Image type is not supported',
    'image.upload.placeholder': 'Click to upload',
    unSupportBlock: 'The current version does not support this Block.',
  },
} as const;

export default resources;
