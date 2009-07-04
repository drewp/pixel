import parallel, time

dataPin = 0
clockPin = 2
latchPin = 3

class Shiftbrite(object):
    def __init__(self, portNum=0):
        self.port = parallel.Parallel(port=portNum)
        self.port.setData(0)
        self.sendCommandMode()

    def dataBit(self, x, i):
        p = 0
        if x:
            p = (1 << dataPin)
        self.port.setData(p)
        self.port.setData(p | (1 << clockPin))

    def latch(self):
        self.port.setData(1 << latchPin)
        self.port.setData(0)


    def sendPacket(self, r, g, b):
        self.dataBit(0, 0)
        self.dataBit(0, 1)
        for col in [r, g, b]:
            col = max(0, min(1023, int(col)))
            for bit in range(10):
                self.dataBit(col & (1<<(9-bit)), '?')
        self.latch()

    def sendCommandMode(self):
        for i, bit in enumerate([
                0, 1,
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # b correct
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # g correct
                    0,
                    0, 0, # clock mode 00=internal
                    1, 1, 1, 1, 1, 1, 1, # r correct
                    ]):
            self.dataBit(bit, i)
        self.latch()


if __name__ == '__main__':
    from math import sin
    sb = Shiftbrite()
    try:
        r = 500
        while 1:
            t = time.time()
            sb.sendCommandMode()
            sb.sendPacket(r + r * sin(t * .8), 
                          r + r * sin(t * .6), 
                          r + r * sin(t * .5))
            time.sleep(.03)
    finally:
        sb.sendPacket(0, 0, 0)

