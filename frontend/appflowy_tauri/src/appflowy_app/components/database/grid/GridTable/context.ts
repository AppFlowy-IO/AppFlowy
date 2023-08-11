import { RefObject, createContext, createRef } from 'react';

export const VerticalScrollElementRefContext = createContext<RefObject<Element>>(createRef());
