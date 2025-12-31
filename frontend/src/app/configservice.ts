import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private config: any;

  constructor(private http: HttpClient) {}

  loadConfig() {
    return firstValueFrom(this.http.get('./assets/config.json'))
      .then(data => {
        this.config = data;
        console.log("Config successfully assigned:", this.config);
      });
  }

  getApiGatewayUrl(): string {
    if (!this.config) {
      console.warn('Config not yet loaded, returning empty string');
      return '';
    }
    return this.config.ApiGatewayUrl;
  }
}
