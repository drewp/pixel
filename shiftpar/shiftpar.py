import parallel, time

dataPin = 0
clockPin = 2
latchPin = 3

class Shiftbrite(object):
    def __init__(self, portNum=0):
        self.port = parallel.Parallel(port=portNum)
        self.port.setData(0)
        self.sendCommandMode()
        self.sendPacket(300, 200, 100)

    def sendPacket(self, r, g, b):
        d = self.port.setData
        d(0)
        d(0 | (1 << clockPin))
        d(0)
        d(0 | (1 << clockPin))
        for bit in range(10):
            val = (r & (1<<bit)) and (1 << dataPin)
            d(val)
            d(val | (1 << clockPin))
        # 15 micro sleep
        d(1 << latchPin)
        d(0)

    def sendCommandMode(self):
        d = self.port.setData
        for bit in [0, 1,
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # b correct
                    0, 0, 0,
                    1, 1, 1, 1, 1, 1, 1, # g correct
                    0,
                    0, 0, # clock mode 00=internal
                    1, 1, 1, 1, 1, 1, 1, # r correct
                    ]:
            d(bit and dataPin)
            d((bit and dataPin) | clockPin)
        d(latchPin)
        d(0)


sb = Shiftbrite()
sb.sendPacket(300, 200, 100)
time.sleep(1)
sb.sendPacket(0, 0, 0)
