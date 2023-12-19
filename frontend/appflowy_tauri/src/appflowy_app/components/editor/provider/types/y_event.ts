import { YXmlText } from 'yjs/dist/src/types/YXmlText';

export interface YOp {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  insert?: string | object | any[] | YXmlText | undefined;
  retain?: number | undefined;
  delete?: number | undefined;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  attributes?: { [p: string]: any } | undefined;
}

export type YDelta = YOp[];
