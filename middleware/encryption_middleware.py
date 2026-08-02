import json
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from security.crypto import encrypt_payload, decrypt_payload

class EncryptionMiddleware(BaseHTTPMiddleware):
	async def dispatch(self, request: Request, call_next):
		# Decrypt incoming JSON body if it's wrapped as {"data": "..."}
		if request.method in ("POST", "PUT", "PATCH") and request.headers.get("content-type", "").startswith("application/json"):
			body_bytes = await request.body()
			if body_bytes:
				try:
					wrapper = json.loads(body_bytes)
					if "data" in wrapper:
						decrypted = decrypt_payload(wrapper["data"])
						new_body = json.dumps(decrypted).encode("utf-8")

						# CRITICAL: overwrite the cached body, not just _receive,
						# otherwise FastAPI's route validation reads the old
						# (still encrypted) bytes and fails with 422.
						request._body = new_body

						async def receive():
							return {"type": "http.request", "body": new_body, "more_body": False}

						request._receive = receive
				except Exception:
					pass  # not encrypted -> let route validation handle it normally

		response = await call_next(request)

		# Only encrypt successful JSON responses; leave errors readable for debugging
		if 200 <= response.status_code < 300 and response.headers.get("content-type", "").startswith("application/json"):
			body = b""
			async for chunk in response.body_iterator:
				body += chunk
			try:
				data = json.loads(body)
				encrypted = encrypt_payload(data)
				new_body = json.dumps({"data": encrypted}).encode("utf-8")
				return Response(
					content=new_body,
					status_code=response.status_code,
					headers={"content-type": "application/json"},
				)
			except Exception:
				return Response(content=body, status_code=response.status_code, headers=dict(response.headers))

		return response
