import { UserService } from '@/application/services/services.type';
import { UserProfile } from '@/application/services/user.type';
import { HttpClient } from '@/application/services/js-services/http/client';

export class JSUserService implements UserService {
  constructor(private httpClient: HttpClient) {}

  async getUserProfile(): Promise<UserProfile> {
    return this.httpClient.getUser();
  }
}
