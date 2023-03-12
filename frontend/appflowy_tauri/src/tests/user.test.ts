export {}
// import { AuthBackendService, UserBackendService } from '../appflowy_app/stores/effects/user/user_bd_svc';
// import { randomFillSync } from 'crypto';
// import { nanoid } from '@reduxjs/toolkit';

// beforeAll(() => {
//   //@ts-ignore
//   window.crypto = {
//     // @ts-ignore
//     getRandomValues: function (buffer) {
//       // @ts-ignore
//       return randomFillSync(buffer);
//     },
//   };
// });

// describe('User backend service', () => {
//   it('sign up', async () => {
//     const service = new AuthBackendService();
//     const result = await service.autoSignUp();
//     expect(result.ok).toBeTruthy;
//   });

//   it('sign in', async () => {
//     const authService = new AuthBackendService();
//     const email = nanoid(4) + '@appflowy.io';
//     const password = nanoid(10);
//     const signUpResult = await authService.signUp({ name: 'nathan', email: email, password: password });
//     expect(signUpResult.ok).toBeTruthy;

//     const signInResult = await authService.signIn({ email: email, password: password });
//     expect(signInResult.ok).toBeTruthy;
//   });

//   it('get user profile', async () => {
//     const service = new AuthBackendService();
//     const result = await service.autoSignUp();
//     const userProfile = result.unwrap();

//     const userService = new UserBackendService(userProfile.id);
//     expect((await userService.getUserProfile()).unwrap()).toBe(userProfile);
//   });
// });
