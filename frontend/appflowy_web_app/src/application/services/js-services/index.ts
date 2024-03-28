import {
  AFService,
  AFServiceConfig,
  AuthService,
  DocumentService,
  UserService,
} from '@/application/services/services.type';
import { JSUserService } from '@/application/services/js-services/user.service';
import { JSAuthService } from '@/application/services/js-services/auth.service';
import { AFWasmService } from '@/application/services/wasm-services';
import { HttpClient } from '@/application/services/js-services/http/client';
import { JSDocumentService } from '@/application/services/js-services/document.service';

export class AFJSService implements AFService {
  authService: AuthService;
  userService: UserService;
  wasmService: AFWasmService;
  httpClient: HttpClient;
  documentService: DocumentService;

  constructor(private config: AFServiceConfig) {
    this.wasmService = new AFWasmService(config);
    this.httpClient = new HttpClient({
      baseURL: config.cloudConfig.baseURL,
      gotrueURL: config.cloudConfig.gotrueURL,
    });
    this.authService = new JSAuthService(this.httpClient);
    this.userService = new JSUserService(this.httpClient);
    this.documentService = new JSDocumentService(this.httpClient);
  }

  async load() {
    await this.wasmService.load();
  }
}
