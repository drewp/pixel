import serial
def getSerial(baud=9600, port='any'):

    ser = None
    if port == 'any':
        ports = ["/dev/ttyUSB0", "/dev/ttyUSB1"]
    else:
        ports = [port]
    for port in ports:
        try:
            ser = serial.Serial(port=port, baudrate=baud, timeout=1,
                                xonxoff=0, rtscts=0)
            break
        except serial.serialutil.SerialException, e:
            print e,
            if port != ports[-1]:
                print ", trying next port"
            else:
                print
    if ser is None:
        raise RuntimeError("can't open any ports")
    print "opened port %s" % port
    return ser
