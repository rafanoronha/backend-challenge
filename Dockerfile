# ============================================
# Multi-stage Dockerfile para Token Service
# Otimizado para produção na AWS ECS Fargate
# ============================================
#
# Usamos Debian em vez de Alpine para evitar problemas de DNS em produção
# Seguindo boas práticas da comunidade Elixir (Fly.io, Gigalixir, etc)

ARG ELIXIR_VERSION=1.18.0
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20241223-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ---------------------------------------------
# Stage 1: Builder - Compila e cria o release
# ---------------------------------------------
FROM ${BUILDER_IMAGE} AS builder

# Instala dependências de build
RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Define diretório de trabalho
WORKDIR /app

# Instala hex e rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Configura ambiente de produção
ENV MIX_ENV=prod

# Instala dependências do Mix
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# Copia arquivos de configuração
COPY config config/
RUN mix deps.compile

# Copia código fonte
COPY lib lib

# Compila a aplicação
RUN mix compile

# Cria o release
RUN mix release

# ---------------------------------------------
# Stage 2: Runner - Imagem final mínima
# ---------------------------------------------
FROM ${RUNNER_IMAGE} AS runner

# Instala apenas dependências de runtime
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configura locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Define diretório de trabalho
WORKDIR /app

# Cria usuário não-root
RUN useradd -m -u 1000 elixir && \
    chown elixir:elixir /app

# Configura ambiente
ENV MIX_ENV=prod

# Copia APENAS o release compilado (standalone)
COPY --from=builder --chown=elixir:elixir /app/_build/${MIX_ENV}/rel/token_service ./

# Muda para usuário não-root
USER elixir

# Expõe porta da aplicação
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Comando de inicialização usando o script do release
CMD ["/app/bin/token_service", "start"]

