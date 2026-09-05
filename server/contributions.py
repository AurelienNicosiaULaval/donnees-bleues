"""Small SMTP bridge for the contribution form. Run behind an HTTPS reverse proxy.
Configuration is read from environment; credentials must never enter the website.
"""
import json
import os
import smtplib
import ssl
import time
import threading
from email.message import EmailMessage
from email.utils import parseaddr
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

FIELDS = ('name', 'email', 'type', 'title', 'url', 'author', 'themes', 'courses', 'message')
LIMITS = dict(zip(FIELDS, (120, 254, 80, 180, 2000, 240, 240, 400, 4000)))
TYPES = {'Données', 'Activité pédagogique', 'Document', 'Application ou tutoriel', 'Correction ou collaboration'}

def validate(data):
    if not isinstance(data, dict):
        raise ValueError('Invalid object')
    clean = {key: data.get(key, '') for key in FIELDS}
    if any(not isinstance(v, str) or len(v) > LIMITS[k] for k, v in clean.items()):
        raise ValueError('Invalid field')
    if data.get('website') or data.get('consent') != 'yes':
        raise ValueError('Invalid consent')
    if any(not clean[k].strip() for k in ('name', 'email', 'title', 'message')):
        raise ValueError('Missing field')
    email = clean['email']
    if '\r' in email or '\n' in email or parseaddr(email)[1] != email or email.count('@') != 1 or ' ' in email:
        raise ValueError('Invalid email')
    if clean['type'] not in TYPES or any(c in clean['title'] for c in '\r\n'):
        raise ValueError('Invalid type or title')
    if clean['url'] and not clean['url'].startswith(('https://', 'http://')):
        raise ValueError('Invalid URL')
    return clean

def deliver(data):
    message = EmailMessage()
    message['From'] = os.environ['SMTP_FROM']
    message['To'] = os.environ['MAIL_TO']
    message['Reply-To'] = data['email']
    message['Subject'] = 'Données bleues : ' + data['title']
    message.set_content('\n\n'.join(f'{k}: {v}' for k, v in data.items()))
    with smtplib.SMTP_SSL(os.environ['SMTP_HOST'], int(os.getenv('SMTP_PORT', '465')), context=ssl.create_default_context(), timeout=12) as smtp:
        smtp.login(os.environ['SMTP_USER'], os.environ['SMTP_PASSWORD'])
        smtp.send_message(message)

class Handler(BaseHTTPRequestHandler):
    # The reverse proxy must also enforce rate and body limits. Do not trust X-Forwarded-For.
    attempts = {}
    lock = threading.Lock()
    def log_message(self, *_):
        pass  # No submitted content, email addresses, or request paths in access logs.
    def allowed(self):
        return self.headers.get('Origin') in os.environ.get('ALLOWED_ORIGINS', '').split(',')
    def respond(self, code):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        if self.allowed():
            self.send_header('Access-Control-Allow-Origin', self.headers['Origin'])
            self.send_header('Vary', 'Origin')
        self.end_headers()
        self.wfile.write(json.dumps({'ok': code == 200}).encode())
    def do_OPTIONS(self):
        if not self.allowed():
            return self.respond(403)
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', self.headers['Origin'])
        self.send_header('Access-Control-Allow-Methods', 'POST')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Vary', 'Origin')
        self.end_headers()
    def do_POST(self):
        self.connection.settimeout(15)
        if self.path != '/contributions':
            return self.respond(404)
        if not self.allowed():
            return self.respond(403)
        now = time.monotonic()
        with self.lock:
            self.attempts = {k: v for k, v in self.attempts.items() if now-v < 60}
            if self.client_address[0] in self.attempts:
                return self.respond(429)
            # Shared across handler instances.
            Handler.attempts = self.attempts
            Handler.attempts[self.client_address[0]] = now
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 32768 or self.headers.get_content_type() != 'application/json':
                return self.respond(400)
            data = validate(json.loads(self.rfile.read(length)))
        except (ValueError, UnicodeError, TimeoutError):
            return self.respond(400)
        try:
            deliver(data)
        except (smtplib.SMTPException, OSError, KeyError):
            return self.respond(503)
        self.respond(200)

if __name__ == '__main__':
    for required in ('SMTP_HOST', 'SMTP_FROM', 'MAIL_TO', 'SMTP_USER', 'SMTP_PASSWORD', 'ALLOWED_ORIGINS'):
        if not os.getenv(required):
            raise SystemExit(f'Missing configuration: {required}')
    ThreadingHTTPServer(('127.0.0.1', int(os.getenv('PORT', '8780'))), Handler).serve_forever()
