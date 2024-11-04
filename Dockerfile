FROM git.orionkindel.com/lum/core.base:latest@sha256:21812109642301dafc216633472fb51a3cbc3ec12c433dfbb0f7726fc7c411ab

RUN mkdir -p /app
WORKDIR /app

COPY package.json bun.lockb .
RUN bun install --ignore-scripts

COPY spago.yaml spago.lock .
COPY ui ./ui
COPY scripts ./scripts

RUN --mount=type=cache,target=.spago \
    --mount=type=cache,target=output \
    spago build --pure

RUN --mount=type=cache,target=.spago \
    --mount=type=cache,target=output \
  set -e; bun bundle
