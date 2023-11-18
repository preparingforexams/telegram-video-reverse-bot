FROM ghcr.io/blindfoldedsurgery/poetry:1.1.1-pipx-3.11-bookworm

USER root
RUN apt-get update -qq \
    && apt-get install -yq --no-recommends ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives \
USER app

COPY [ "poetry.toml", "poetry.lock", "pyproject.toml", "./" ]

RUN poetry install --no-interaction --ansi --only=main --no-root

# We don't want the tests
COPY src/app ./src/app

RUN poetry install --no-interaction --ansi --only-root

ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

ENTRYPOINT [ "tini", "--", "poetry", "run", "python", "-m", "app" ]
