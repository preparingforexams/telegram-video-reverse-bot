import logging
import mimetypes
import signal
import tempfile
from asyncio import StreamReader, subprocess
from pathlib import Path
from typing import Any, cast

import sentry_sdk
import telegram
from telegram.constants import ChatType, FileSizeLimit
from telegram.ext import Application, MessageHandler, filters

from app.config import Config

_LOG = logging.getLogger(__name__)


class Bot:
    def __init__(self, config: Config):
        self.config = config

    def run(self) -> None:
        app = Application.builder().token(self.config.telegram_token).build()
        app.add_handler(MessageHandler(filters.VIDEO, self._handle_message))
        app.run_polling(
            stop_signals=[signal.SIGINT, signal.SIGTERM],
        )

    async def _handle_message(self, update: telegram.Update, _: Any) -> None:
        if update.edited_message:
            _LOG.info("Skipping edited message update")
            return

        _LOG.info("Received update")
        message = cast(telegram.Message, update.message)
        if message.chat.type != ChatType.PRIVATE:
            await message.reply_text(
                "I can't do it when I'm being watched."
                " Please send me your videos in a private chat.",
            )
            return

        video = cast(telegram.Video, message.video)
        file_size = video.file_size
        if file_size is not None and file_size > FileSizeLimit.FILESIZE_DOWNLOAD.value:
            await message.reply_text(
                "Sorry, I can only handle videos up to 20 MB.",
            )
            return

        with tempfile.TemporaryDirectory() as tmpdir:
            working_dir = Path(tmpdir)
            original_file = await self._download_video(video, working_dir)
            reversed_file = await self._convert_video(original_file, working_dir)
            if reversed_file is None:
                await message.reply_text(
                    "Sorry, I failed reversing that one 🤷‍♂️",
                )
            else:
                await message.reply_video(
                    video=reversed_file,
                )

    async def _download_video(self, video: telegram.Video, working_dir: Path) -> Path:
        _LOG.info("Downloading file with ID %s", video.file_id)
        file = await video.get_file()
        file_name = self._determine_file_name(video)
        return await file.download_to_drive(working_dir / file_name)

    async def _convert_video(
        self, original_file: Path, working_dir: Path
    ) -> Path | None:
        _LOG.info("Converting file %s", original_file)
        target_file = working_dir / f"r{original_file.name}"
        process = await subprocess.create_subprocess_exec(
            "ffmpeg",
            "-i",
            original_file.name,
            "-vf",
            "reverse",
            "-af",
            "areverse",
            target_file.name,
            cwd=working_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        exit_code = await process.wait()

        if exit_code == 0:
            _LOG.info("Finished conversion.")
            return target_file
        else:
            try:
                output_bytes = await cast(StreamReader, process.stdout).read()
                error_bytes = await cast(StreamReader, process.stderr).read()
                sentry_sdk.set_extra("ffmpeg_stdout", output_bytes.decode("utf-8"))
                sentry_sdk.set_extra("ffmpeg_stderr", error_bytes.decode("utf-8"))
            finally:
                _LOG.error("Received exit code %d from ffmpeg.", exit_code)

            return None

    @staticmethod
    def _determine_file_name(video: telegram.Video) -> str:
        file_name = video.file_name
        if file_name is not None:
            return file_name

        mime_type = video.mime_type
        if mime_type is None:
            _LOG.warning("Did not get mime type from telegram")
            return "video.mp4"

        extension = mimetypes.guess_extension(mime_type, strict=True) or ".mp4"
        return f"video{extension}"
