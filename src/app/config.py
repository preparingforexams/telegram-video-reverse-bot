from dataclasses import dataclass
from typing import Self

from bs_config import Env
from bs_nats_updater import NatsConfig


@dataclass(frozen=True)
class Config:
    app_version: str
    nats: NatsConfig
    sentry_dsn: str | None
    telegram_token: str

    @classmethod
    def from_env(cls) -> Self:
        env = Env.load()

        return cls(
            app_version=env.get_string("APP_VERSION", default="dev"),
            nats=NatsConfig.from_env(env.scoped("NATS_")),
            sentry_dsn=env.get_string("SENTRY_DSN"),
            telegram_token=env.get_string("TELEGRAM_TOKEN", required=True),
        )
