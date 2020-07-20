import subprocess
import requests
import os
import json
import boto3
import mimetypes


def handle_update(update, context):
    message = update['message']

    if message['chat']['type'] == "private":
        return _handle_private_message(message)
    else:
        return _result_message_body(message, "I can't do it when I'm being watched. Please send me your videos in a private chat.")


def _handle_private_message(message: dict):
    video = message.get('video')
    if not video:
        return
    return _handle_video(message, video)


def _result_message_body(message: dict, text: str) -> dict:
    body = _send_message_body(message, text)
    body['method'] = "sendMessage"


def _send_message_body(message: dict, text: str) -> dict:
    return {
        'chat_id': message['chat']['id'],
        'reply_to_message_id': message['message_id'],
        'text': text
    }


# Limit by Telegram
_max_file_size_bytes = 20 * 1024 * 1024


def _handle_video(message: dict, video: dict):
    file_size_bytes = video['file_size']
    if file_size_bytes > _max_file_size_bytes:
        return _result_message_body(message, "Sorry, I can only handle videos up to 20 MB.")

    _invoke_convert(
        {
            'file_id': video['file_id'],
            'mime_type': video['mime_type'],
            'chat_id': message['chat']['id'],
            'message_id': message['message_id']
        }
    )


def _invoke_convert(args: dict):
    lamb = boto3.client('lambda')
    return lamb.invoke(
        FunctionName=os.getenv('CONVERT_LAMBDA_NAME'),
        InvocationType='Event',
        Payload=json.dumps(args)
    )


def convert(args: dict, context):
    file_id = args['file_id']
    mime_type = args['mime_type']
    chat_id = args['chat_id']
    message_id = args['message_id']
    ext = mimetypes.guess_extension(mime_type)
    if not ext:
        # Send message
        return
    file = _download_file(file_id, ext)
    reversed_file = _reverse(file, ext)
    _send_video(chat_id, message_id, mime_type, reversed_file)


def _download_file(file_id, ext):
    file = _make_request("getFile", {'file_id': file_id})
    file_path = file['result']['file_path']
    target_file = f"/tmp/{file_id}{ext}"
    with open(target_file, 'wb') as f:
        with requests.get(f"https://api.telegram.org/file/bot{_token}/{file_path}", stream=True) as r:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    return target_file


_token = os.getenv('TELEGRAM_TOKEN')


def _make_request(method: str, body: dict):
    return requests.post(_request_url(method), data=body).json()


def _request_url(method: str):
    return f"https://api.telegram.org/bot{_token}/{method}"


def _reverse(file, ext):
    print(f"Reversing: {file}")
    out_file = f"{file}-reversed{ext}"
    return_code = subprocess.call(
        [
            '/opt/ffmpeg/ffmpeg',
            "-i", file,
            "-vf", "reverse",
            "-af", "areverse",
            out_file
        ]
    )
    print(f"Reversed with code: {return_code}")

    if return_code != 0:
        raise ValueError(f'Return code: {return_code}')

    return out_file


def _send_video(chat_id, message_id, mime_type, _reversed_file):
    try:
        resp = requests.post(
            _request_url('sendVideo'),
            data={
                'chat_id': chat_id,
                'reply_to_message_id': message_id,
                'video': 'attach://vid'
            },
            files={'vid': (_reversed_file,  open(
                _reversed_file, 'rb'), mime_type, {})}
        )
        print(resp.json())
    except BaseException as e:
        print(e)
