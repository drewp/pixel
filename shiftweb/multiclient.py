"""
send updates to shiftweb servers across multiple machines
"""
from __future__ import division
import logging
import restkit
from cyclone.httpclient import fetch
from shiftweb import hexFromRgb
log = logging.getLogger()

def setColor8(lightName, rgb):
    """takes 8-bit r,g,b"""
    return setColor(lightName, [x * 4 for x in rgb])

lightResource = {
    'deskLeft' :     'http://dash:9014/brite/0',
    'deskRight' :    'http://dash:9014/brite/1',
    'bathroom' :     'http://slash:9050/brite/0',
    'ari1' :         'http://star:9014/brite/0',
    'ari2' :         'http://star:9014/brite/1',
    'ari3' :         'http://star:9014/brite/2',
    'bedroom' :      'http://bang:9060/brite/0',
    'bedroomWall0' : 'http://bang:9060/brite/1',
    'bedroomWall1' : 'http://bang:9060/brite/2',
    'bedroomWall2' : 'http://bang:9060/brite/3',
    'bedroomWall3' : 'http://bang:9060/brite/4',
    'slash-zwave' :  'http://slash:9082', 
    }

def setColor(lightName, rgb, _req=restkit.request):
    """takes 10-bit r,g,b

    returns even if the server is down
    """
    log.debug("setColor(%r,%r)", lightName, rgb)
    if lightName == 'bedroomBall':
        try:
            r = _req(method='PUT', url=lightResource['slash-zwave'],
                 body="%g" % (rgb[0]/1024), headers={})
            return r
        except Exception, e:
            log.warn(e)
            return
    
    serv = lightResource[lightName]
    try:
        h = hexFromRgb(rgb)
        log.debug("put %r to %r", h, serv)
        r = _req(method='PUT', url=serv, body=h,
             headers={"content-type":"text/plain"})
        return r
    except Exception, e:
        log.warn("Talking to: %r" % serv)
        log.warn(e)
        return None

def setColorAsync(lightName, rgb):
    """
    uses twisted http, return deferred or sometimes None when there
    was a warning
    """
    def _req(method, url, body, headers):
        d = fetch(url=url, method=method, postdata=body,
                  headers=dict((k,[v]) for k,v in headers.items()))
        @d.addErrback
        def err(e):
            log.warn("http client error on %s: %s" % (url, e))
            raise e
        return d
    setColor(lightName, rgb, _req=_req)
