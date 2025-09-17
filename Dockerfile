# renovate: datasource=docker depName=debian versioning=debian
ARG DEBIAN_VERSION="trixie"

# renovate: datasource=python-version depName=python versioning=python
ARG PYTHON_VERSION="3.13"

# renovate: datasource=pypi depName=uv versioning=semver-coerced
ARG UV_VERSION="0.8.18"

FROM ghcr.io/astral-sh/uv:${UV_VERSION}-python${PYTHON_VERSION}-${DEBIAN_VERSION}-slim

RUN apt-get update -qq \
    && apt-get install -yq --no-install-recommends ffmpeg tini  \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN groupadd --system --gid 1000 app
RUN useradd --system --uid 1000 --gid app --create-home --home-dir /app app

USER 1000
WORKDIR /app

COPY [ "uv.lock", "pyproject.toml", "./" ]

RUN uv sync --locked --no-install-workspace --all-extras --no-dev

# We don't want the tests
COPY src/app ./src/app

RUN uv sync --locked --no-editable --all-extras --no-dev

ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

ENV UV_NO_SYNC=true
ENTRYPOINT [ "tini", "--", "uv", "run", "-m", "app" ]
