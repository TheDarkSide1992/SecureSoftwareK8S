FROM node:latest AS build
WORKDIR /app
COPY /frontend/package*.json /app/
RUN npm install -g ionic
RUN npm install
COPY /frontend /app
RUN npm run build --prod

FROM nginx:alpine
COPY --from=build /app/www/ /usr/share/nginx/html/www
COPY /frontend/nginx.conf  /etc/nginx/conf.d/default.conf
RUN mkdir -p /usr/share/nginx/html/www/assets

EXPOSE 4200
