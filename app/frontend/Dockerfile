FROM node:alpine AS base

WORKDIR /usr/src/app

COPY yarn.lock ./
COPY package.json ./

RUN yarn install --frozen-lockfile

FROM node:alpine AS build

WORKDIR /usr/src/app

COPY --from=base /usr/src/app/node_modules ./node_modules

COPY . .

RUN yarn build

FROM nginx:alpine AS production

WORKDIR /usr/src/app

COPY --from=build /usr/src/app/dist /usr/share/nginx/html

COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx","-g","daemon off;"]