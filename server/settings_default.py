# If you want to override some of the settings
# overwrite in file 'settings.py' in server root
# when call

DEBUG = False
TESTING = False
MONGODB_SETTINGS = {'DB': 'testing'}
SECRET_KEY= 'flask+mongoengine<=3'

# Flask-login
# https://flask-login.readthedocs.io/en/latest/#flask_login.LoginManager
SESSION_PROTECTION = 'basic'

# mail settings
MAIL_SERVER = 'smtp.gmail.com'
MAIL_PORT = 465
MAIL_USE_SSL = True
MAIL_USERNAME = 'set_in_settings'
MAIL_PASSWORD = 'password?'
MAIL_DEFAULT_SENDER = 'same_as_username'

BESTMINER_UPDATE_WTM_DELAY = 600
BESTMINER_UPDATE_WTM = False

BESTMINER_EXCHANGES_AUTOUPDATE = False
BESTMINER_EXCHANGES_AUTOUPDATE_PERIOD = 300
BESTMINER_EXCHANGES_UPDATE_ONCE_AT_START = False
