FROM node:alpine as base

WORKDIR /usr/src/app

COPY yarn.lock ./
COPY package.json ./

RUN yarn install --frozen-lockfile

FROM node:alpine as build

WORKDIR /usr/src/app

COPY --from=base /usr/src/app/node_modules ./node_modules

COPY . .

CMD ["yarn", "start"]
