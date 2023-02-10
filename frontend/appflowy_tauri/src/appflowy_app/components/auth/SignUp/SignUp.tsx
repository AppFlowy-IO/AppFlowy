import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { EyeClosed } from '../../_shared/svg/EyeClosedSvg';
import { EyeOpened } from '../../_shared/svg/EyeOpenSvg';

import { useSignUp } from './SignUp.hooks';
import { Link } from 'react-router-dom';
import { Button } from '../../_shared/Button';

export const SignUp = () => {
  const { showPassword, onTogglePassword, showConfirmPassword, onToggleConfirmPassword, onSignUpClick } = useSignUp();

  return (
    <form method='POST' onSubmit={(e) => e.preventDefault()}>
      <div className='flex h-screen w-full flex-col items-center justify-center gap-12 text-center'>
        <div className='flex h-10 w-10 justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold'>Sign up to Appflowy</span>
        </div>

        <div className='flex w-full max-w-[340px]  flex-col gap-6'>
          <input type='text' className='input w-full' placeholder='Phone / Email' />
          <div className='relative w-full'>
            <input type={showPassword ? 'text' : 'password'} className='input w-full !pr-10' placeholder='Password' />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onTogglePassword}
              type='button'
            >
              <span className='h-6 w-6'>{showPassword ? <EyeClosed /> : <EyeOpened />}</span>
            </button>
          </div>

          <div className='relative w-full'>
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              className='input w-full !pr-10'
              placeholder='Repeat Password'
            />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onToggleConfirmPassword}
              type='button'
            >
              <span className='h-6 w-6'>{showConfirmPassword ? <EyeClosed /> : <EyeOpened />}</span>
            </button>
          </div>
        </div>

        <div className='flex w-full max-w-[340px] flex-col gap-6 '>
          <Button size={'primary'} onClick={() => onSignUpClick()}>
            Get Started
          </Button>

          {/* signup link */}
          <div className='flex justify-center'>
            <span className='text-xs text-gray-500'>
              Already have an account?
              <Link to={'/auth/login'}>
                <span className=' text-main-accent hover:text-main-hovered'> Sign in</span>
              </Link>
            </span>
          </div>
        </div>
      </div>
    </form>
  );
};
