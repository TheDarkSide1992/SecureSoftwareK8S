import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private config: any;

  constructor(private http: HttpClient) {}

  // This method will be called during app initialization
  loadConfig() {
    return firstValueFrom(
      this.http.get('/assets/config.json')
    ).then(config => {
      this.config = config;
    });
  }

  getApiGatewayUrl() {
    return this.config?.apiGatewayUrl;
  }
}
