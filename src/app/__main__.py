import asyncio
import logging

import sentry_sdk
import uvloop

from app.bot import Bot
from app.config import Config

_LOG = logging.getLogger("app")


def main() -> None:
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

    logging.basicConfig(level=logging.WARNING)
    _LOG.setLevel(logging.INFO)

    config = Config.from_env()

    if config.sentry_dsn:
        sentry_sdk.init(
            dsn=config.sentry_dsn,
            release=config.app_version,
        )
    else:
        _LOG.warning("Sentry is not enabled.")

    bot = Bot(config)
    bot.run()


main()
