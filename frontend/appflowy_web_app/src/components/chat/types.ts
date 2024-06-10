export enum OpenAIModel {
  DAVINCI_TURBO = 'gpt-3.5-turbo',
}

export type Source = {
  url: string;
  text: string;
};

export type SearchQuery = {
  query: string;
};
