"""
send updates to shiftweb servers across multiple machines
"""
from restkit import Resource
from shiftweb import hexFromRgb

def setColor8(lightName, rgb):
    """takes 8-bit r,g,b"""
    return setColor(lightName, [x * 4 for x in rgb])

def setColor(lightName, rgb):
    """takes 10-bit r,g,b"""
    serv, chan = {
        'deskLeft' : ('http://dash:9014/', 1),
        'deskRight' : ('http://dash:9014/', 0),
        'bathroom' : ('http://slash:9014/', 0),
        }[lightName]
    Resource(serv).post("color", channel=chan, color=hexFromRgb(rgb))

