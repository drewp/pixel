"""
send updates to shiftweb servers across multiple machines
"""
import logging
from restkit import Resource, RequestError, RequestFailed
from shiftweb import hexFromRgb
log = logging.getLogger()

def setColor8(lightName, rgb):
    """takes 8-bit r,g,b"""
    return setColor(lightName, [x * 4 for x in rgb])

server = {
    'dash' : Resource('http://dash:9014/'),
    'slash' : Resource('http://slash:9014/'),
    'score' : Resource('http://score:9014/'),
    }
def setColor(lightName, rgb):
    """takes 10-bit r,g,b

    returns even if the server is down
    """
    serv, chan = {
        'deskLeft' : (server['dash'], 1),
        'deskRight' : (server['dash'], 0),
        'bathroom' : (server['slash'], 0),
        'ari1' : (server['score'], 0),
        'ari2' : (server['score'], 1),
        'ari3' : (server['score'], 2),
        }[lightName]
    try:
        serv.post("color", channel=chan, color=hexFromRgb(rgb))
    except (RequestError, RequestFailed), e:
        log.warn(e)
        

