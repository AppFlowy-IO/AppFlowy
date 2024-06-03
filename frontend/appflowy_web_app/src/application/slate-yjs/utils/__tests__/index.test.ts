import { runCollaborationTest } from './convert';
import { runApplyRemoteEventsTest } from './applyRemoteEvents';

describe('slate-yjs adapter', () => {
  it('should pass the collaboration test', async () => {
    await runCollaborationTest();
  });

  it('should pass the apply remote events test', async () => {
    await runApplyRemoteEventsTest();
  });
});
