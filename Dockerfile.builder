# syntax=docker/dockerfile:1
FROM node:20-slim
ARG VOLTO_VERSION
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

LABEL maintainer="Plone Community <dev@plone.org>" \
      org.label-schema.name="frontend-base" \
      org.label-schema.description="Plone frontend builder image" \
      org.label-schema.vendor="Plone Foundation"

RUN <<EOT
    set -e
    apt update
    apt install -y --no-install-recommends python3 python3-pip build-essential git ca-certificates pipx
    npm install --no-audit --no-fund -g mrs-developer
    rm -rf /var/lib/apt/lists/*
    pipx run cookiecutter gh:plone/cookiecutter-volto addon_name=app --no-input
    chown -R node:node /app
EOT

COPY --chown=node:node volto.config.js /app/.

RUN corepack enable
USER node

WORKDIR /app

RUN <<EOT
    set -e
    sed -i 's/${VOLTO_VERSION}/'"$VOLTO_VERSION"'/g' mrs.developer.json
    # Removes the addon dependency from package.json
    python3 -c "import json; data = json.load(open('package.json')); data['dependencies'].pop(list(data['dependencies'].keys())[-1]); json.dump(data, open('package.json', 'w'), indent=2)"
    rm -rf packages/app
    make install
EOT

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install
