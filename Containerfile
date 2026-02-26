# ---------- BUILD ----------
FROM hexpm/elixir:1.17.0-rc.0-erlang-27.0-rc1-debian-bullseye-20260223-slim AS build

# Dependencias básicas
RUN apt-get update && apt-get install -y \
  build-essential git npm \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod

# Copiar y compilar deps
COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

# Assets
COPY assets assets
RUN npm --prefix assets install
RUN npm --prefix assets run deploy || \
    (mix esbuild default --minify && mix phx.digest)

# Código y release
COPY priv priv
COPY lib lib
RUN mix compile
RUN mix release

# ---------- RUNTIME ----------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
  openssl libstdc++6 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/_build/prod/rel/anotao ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

CMD ["bin/anotao", "start"]
