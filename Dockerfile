FROM node:12.19.0-alpine AS base

ENV NODE_ENV=production

RUN npm i -g npm@latest

WORKDIR /misskey

FROM base AS builder

RUN apk add --no-cache \
    autoconf \
    automake \
    file \
    g++ \
    gcc \
    libc-dev \
    libtool \
    make \
    nasm \
    pkgconfig \
    python \
    zlib-dev

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    vips-dev \
    vips \
    libimagequant-dev \
    libimagequant

COPY package.json ./
COPY .yarnrc ./
RUN yarn install
COPY . ./
RUN yarn build

FROM base AS runner

RUN apk add --no-cache \
    ffmpeg \
    tini
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    vips
RUN npm i -g web-push
ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=builder /misskey/node_modules ./node_modules
COPY --from=builder /misskey/built ./built
COPY . ./

CMD ["npm", "run", "migrateandstart"]
