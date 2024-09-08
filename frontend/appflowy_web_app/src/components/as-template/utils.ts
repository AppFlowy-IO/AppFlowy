export function slugify (text: string) {
  return text
    .toString() // ensure the text is a string
    .toLowerCase() // make the text lowercase
    .trim() // remove leading and trailing whitespaces
    .replace(/\s+/g, '-') // replace all whitespaces with '-'
    .replace(/[^\w-]+/g, '') // remove all non-word characters
    .replace(/--+/g, '-'); // replace multiple '-' with single '-'
}