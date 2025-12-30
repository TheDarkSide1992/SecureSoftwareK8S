import { NgModule, provideAppInitializer, inject } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouteReuseStrategy } from '@angular/router';

import { IonicModule, IonicRouteStrategy } from '@ionic/angular';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import {provideHttpClient, withFetch} from "@angular/common/http";
import { ConfigService } from "./configservice";

@NgModule({
  declarations: [AppComponent],
  imports: [BrowserModule, IonicModule.forRoot(), AppRoutingModule],
  providers: [provideAppInitializer(() => {
    const configService = inject(ConfigService);
    return configService.loadConfig();
  }),{ provide: RouteReuseStrategy, useClass: IonicRouteStrategy },
    provideHttpClient(withFetch())],
  bootstrap: [AppComponent],
})
export class AppModule {}
