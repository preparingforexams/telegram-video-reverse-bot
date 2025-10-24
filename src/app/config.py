from dataclasses import dataclass
from pathlib import Path
from typing import Self

from bs_config import Env
from bs_nats_updater import NatsConfig


@dataclass(frozen=True)
class Config:
    app_version: str
    nats: NatsConfig
    scratch_dir: Path
    sentry_dsn: str | None
    telegram_token: str

    @classmethod
    def from_env(cls) -> Self:
        env = Env.load()

        return cls(
            app_version=env.get_string("app-version", default="dev"),
            nats=NatsConfig.from_env(env / "nats"),
            scratch_dir=Path(env.get_string("scratch-dir", default="/tmp")),
            sentry_dsn=env.get_string("sentry-dsn"),
            telegram_token=env.get_string("telegram-token", required=True),
        )
