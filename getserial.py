import serial
def getSerial():

    ser = None
    ports = ["/dev/ttyUSB0", "/dev/ttyUSB1"]
    for port in ports:
        try:
            ser = serial.Serial(port=port, baudrate=9600, timeout=1,
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
