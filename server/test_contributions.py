"""Transport and validation tests. No email is sent."""
import http.client
import json
import os
import threading
import unittest
from unittest.mock import patch
from http.server import ThreadingHTTPServer
import contributions as app

class ContributionsTest(unittest.TestCase):
    def setUp(self):
        self.data = dict(name='Test', email='test@example.com', type='Document', title='Ressource',
                         message='Description', consent='yes', website='')
    def test_validation_rejects_injection_and_missing_consent(self):
        for change in ({'email':'x@example.com\r\nBcc: y@example.com'}, {'title':'titre\nBcc'},
                       {'consent':''}, {'website':'spam'}, {'url':'javascript:alert(1)'}, {'message':'x'*4001}):
            with self.assertRaises(ValueError):
                app.validate(self.data | change)
        self.assertEqual(app.validate(self.data)['title'], 'Ressource')
    def test_http_origin_rate_limit_and_delivery_failure(self):
        server = ThreadingHTTPServer(('127.0.0.1', 0), app.Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        def post(origin='https://example.com'):
            connection = http.client.HTTPConnection(*server.server_address)
            connection.request('POST', '/contributions', json.dumps(self.data),
                               {'Origin':origin, 'Content-Type':'application/json'})
            response = connection.getresponse()
            code = response.status
            response.read()
            connection.close()
            return code
        try:
            with patch.dict(os.environ, {'ALLOWED_ORIGINS':'https://example.com'}), patch.object(app, 'deliver') as delivery:
                app.Handler.attempts.clear()
                self.assertEqual(post('https://wrong.example'), 403)
                delivery.assert_not_called()
                self.assertEqual(post(), 200)
                delivery.assert_called_once()
                self.assertEqual(post(), 429)
                app.Handler.attempts.clear()
                delivery.side_effect = OSError('SMTP unavailable')
                self.assertEqual(post(), 503)
        finally:
            server.shutdown()
            server.server_close()
if __name__ == '__main__':
    unittest.main()
