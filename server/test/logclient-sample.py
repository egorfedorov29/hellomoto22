import logging, logging.handlers

clientID = 'THECLIENT'
rootLogger = logging.getLogger('')
rootLogger.setLevel(logging.DEBUG)
socketHandler = logging.handlers.SocketHandler('localhost',
                                               logging.handlers.DEFAULT_TCP_LOGGING_PORT)
# don't bother with a formatter, since a socket handler sends the event as
# an unformatted pickle
rootLogger.addHandler(socketHandler)

class MinerFilter(logging.Filter):
    """
    This is a filter which injects contextual information into the log.
    """

    def filter(self, record):
        record.client_id = clientID
        return True


f = MinerFilter()
rootLogger.addFilter(f)
# Now, we can log to the root logger, or any other logger. First the root...
logging.info('Jackdaws love my big sphinx of quartz.')

# Now, define a couple of other loggers which might represent areas in your
# application:

logger1 = logging.getLogger('myapp.area1')
logger1.addFilter(f)
logger2 = logging.getLogger('myapp.area2')
logger2.addFilter(f)

logger1.debug('Quick zephyrs blow, vexing daft Jim.', )
logger1.info('How quickly daft jumping zebras vex.')
logger2.warning('Jail zesty vixen who grabbed pay from quack.')
logger2.error('The five boxing wizards jump quickly.')
