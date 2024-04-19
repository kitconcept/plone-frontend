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
    rm -rf /var/lib/apt/lists/*
EOT

RUN <<EOT
    pipx run cookiecutter gh:plone/cookiecutter-volto addon_name=app --no-input
    chown -R node:node /app
    cd /app
    sed -i 's/${VOLTO_VERSION}/'"$VOLTO_VERSION"'/g' mrs.developer.json
    # Removes the addon dependency from package.json
    python3 -c "import json; data = json.load(open('package.json')); data['dependencies'].pop(list(data['dependencies'].keys())[-1]); json.dump(data, open('package.json', 'w'), indent=2)"
    rm -rf packages/app
EOT

COPY --chown=node:node volto.config.js /app/

RUN corepack enable
USER node

WORKDIR /app

RUN --mount=type=cache,id=pnpm,target=/app/.pnpm-store,uid=1000 <<EOT
    set -e
    pnpm dlx mrs-developer missdev --no-config --fetch-https
    pnpm install
EOT
