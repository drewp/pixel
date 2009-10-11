from __future__ import division
import parallel, time

class DummyPort(object):
    def setData(self, d):
        pass

class ShiftbriteParallel(object):
    """
    Communicate to ShiftBrite or MegaBrite units over a parallel port. 

    On linux, you may need to 'rmmod lp' to be able to open the port.
    """
    def __init__(self, portNum=0, pins={'data' : 0, 'clock' : 2, 'latch' : 3},
                 dummyModeOk=False, numChannels=1):
        """
        If dummyModeOk is set, a failure to open the parallel port
        will be ignored, and further output commands will have no
        effect. This might be useful for testing.
        """
        try:
            self.port = parallel.Parallel(port=portNum)
        except (OSError, AttributeError):
            if not dummyModeOk:
                raise
            self.port = DummyPort()
        self.port.setData(0)
        self._dataVal = 1 << pins['data']
        self._clockVal = 1 << pins['clock']
        self._latchVal = 1 << pins['latch']
        self.numChannels = numChannels
        
    def _dataBit(self, x):
        out = 0
        if x:
            out = self._dataVal
        self.port.setData(out)
        self.port.setData(out | self._clockVal)

    def _latch(self):
        self.port.setData(self._latchVal)

    def sendColors(self, rgbs):
        """set colors of shiftbrites down the chain. 
        Pass a list of [(r1,g1,b1), (r2, g2, b2), ...]
        Values are 0..1023.
        
        See http://docs.macetech.com/doku.php/megabrite
        """
        for rgb in rgbs:
            self._dataBit(0)
            self._dataBit(0)
            for col in rgb[2], rgb[0], rgb[1]:
                col = max(0, min(1023, int(col)))
                for bit in range(10):
                    self._dataBit(col & (1<<(9-bit)))
        self._latch()

    def setModes(self, numChannels=1):
        """set mode and calibration for numChannels shiftbrites. Call
        this anytime your units might have gotten random noise and
        changed modes, perhaps just before each color command.
        
        See http://docs.macetech.com/doku.php/megabrite
        """
        for loop in range(numChannels):
            for i, bit in enumerate([
                    0, 1,
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # b correction
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # g correction
                    0,
                    0, 0, # clock mode 00=internal
                    1, 1, 1, 1, 1, 1, 1, # r correction
                    ]):
                self._dataBit(bit)
        self._latch()

    def update(self, colors):
        self.setModes(self.numChannels)
        self.sendColors(colors)

if __name__ == '__main__':
    from math import sin
    sb = ShiftbriteParallel()
    try:
        r = 500
        while 1:
            t = time.time()
            sb.setModes(1)
            sb.sendColors([(r + r * sin(t * .8), 
                            r + r * sin(t * .6), 
                            r + r * sin(t * .5))])
            time.sleep(.03)
    finally:
        sb.sendPacket(0, 0, 0)

