import { Component, inject } from '@angular/core';
import {CreateGameDto} from "../Models/CreateGameDto";
import {environment} from "../../environments/environment";
import {firstValueFrom} from "rxjs";
import {HttpClient} from "@angular/common/http";
import {SearchDto} from "../Models/SearchDto";
import { ConfigService } from "../configservice";

@Component({
  selector: 'app-search-page',
  templateUrl: 'search-page.html',
  styleUrls: ['search-page.scss'],
  standalone: false,
})
export class SearchPage {
  gamelist : SearchDto[] = [];

  constructor(private http: HttpClient, private configService: ConfigService) {}

  baseUrl(): string {
    return this.configService.getApiGatewayUrl() || '';
  }


  async search(query: string)
  {
    try {
      this.gamelist = [];
      const call = this.http.get<SearchDto[]>(this.baseUrl() + "Search?query=" + query);
      /*const result = await firstValueFrom<SearchDto[]>(call);
      this.gamelist = result;*/
      call.subscribe((resData: SearchDto[]) => {
        this.gamelist = resData;
        console.log(this.gamelist)
      })
    } catch (error) {
      // @ts-ignore
      if (error.status === 404) {
        console.log("could not find response for " + query);
      } else {
        console.error("Unexpected error " + error);
      }
    }
  }

  openDetailedGamePage(gameId: string)
  {
    window.location.href = "/game/" + gameId;
  }


}
