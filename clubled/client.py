import serial, sys, time

# from http://www.pjrc.com/teensy/td_digital.html, teensy 2.0
PIN_F0 = 21
PIN_F1 = 20

class Board(object):
    def __init__(self, port='/dev/ttyACM0', debug=False):
        """
        set debug=True and we won't read the 'ok' after each
        message. Use readForever to see everything that's coming back
        from the board
        """
        self.ser = serial.Serial(port=port)
        self.debug = debug
        self.resetComm()
        
    def resetComm(self):
        self.ser.write('\x00' * 220)

    def assignAddresses(self, pin=PIN_F0, count=50):
        self.ser.write(''.join(map(chr, [0x60, 0x1E, 0xD5, pin, 0, count])))
        self._getOk()

    def _getOk(self):
        if self.debug:
            return
        ret = self.ser.read(2)
        if ret != 'ok':
            raise ValueError("got %r" % ret)

    def setColors(self, pin, colors):
        """
        colors is a list of tuples: (addr, intensity, r, g, b)
        intensity is 0..255, but 0xcc==204 is recommended.
        r,g,b are 0..15

        This takes 10-44 ms to run, 44ms if you send 50 colors.
        """
        msg = [0x60, 0x1E, 0xD5, pin, len(colors)]
        for addr, intensity, r, g, b in colors:
            color16 =r+(g<<4)+(b<<8)
            msg.extend([addr, intensity, color16 >> 8, color16 & 0xff])
        self.ser.write(''.join(map(chr, msg)))
        self._getOk()

    def readForever(self):
        """
        if you're debugging, run this at the end to echo all the bytes
        that come back from the board
        """
        while 1:
            byte = board.ser.read(1)
            sys.stdout.write("got 0x%02x %d %r\n" %
                             (ord(byte), ord(byte), byte))
            sys.stdout.flush()

if __name__ == '__main__':
    board = Board()

    board.assignAddresses(PIN_F0)
    t = time.time()
    for loop in range(100):
        board.setColors(PIN_F0, [(0, 204, 15, 15, 15)] * 20)
    print "%.1f fps" % (1. / ((time.time() - t) / 100.))
    #board.readForever()
