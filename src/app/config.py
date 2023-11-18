from dataclasses import dataclass
from typing import Self

from bs_config import Env


@dataclass(frozen=True)
class Config:
    app_version: str
    sentry_dsn: str | None
    telegram_token: str

    @classmethod
    def from_env(cls) -> Self:
        env = Env.load()

        return cls(
            app_version=env.get_string("APP_VERSION", default="dev"),
            sentry_dsn=env.get_string("SENTRY_DSN"),
            telegram_token=env.get_string("TELEGRAM_TOKEN", required=True),
        )
