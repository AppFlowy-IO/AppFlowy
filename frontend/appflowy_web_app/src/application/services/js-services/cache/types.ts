export enum StrategyType {
  // Cache only: return the cache if it exists, otherwise throw an error
  CACHE_ONLY = 'CACHE_ONLY',
  // Cache first: return the cache if it exists, otherwise fetch from the network
  CACHE_FIRST = 'CACHE_FIRST',
  // Cache and network: return the cache if it exists, otherwise fetch from the network and update the cache
  CACHE_AND_NETWORK = 'CACHE_AND_NETWORK',
  // Network only: fetch from the network and update the cache
  NETWORK_ONLY = 'NETWORK_ONLY',
}

export type Fetcher<T> = () => Promise<T>;
