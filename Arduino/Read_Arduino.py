import serial
import pyqtgraph as pg
import array
import pyautogui
from threading import Timer
from scipy import signal
import socket
import serial.tools.list_ports

# Arduino = serial.Serial("COM5", 115200)
plist = list(serial.tools.list_ports.comports())
if len(plist) <= 0:
    print("The Serial port can't find!")
else:
    plist_0 = list(plist[2])
    serialName = plist_0[0]
    Arduino = serial.Serial(
        port=serialName,
        baudrate=115200,
        bytesize=serial.SEVENBITS
    )
channelNumber = 8  # 通道数量
motor = 0
count = 0
flag = [0, 0, 0, 0, 0]
Key = ["1", "2", "3", "4", "5"]

pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')
app = pg.mkQApp()  # 建立app
win = pg.GraphicsWindow()  # 建立窗口
win.setWindowTitle('Plot')
win.resize(800, 500)  # 小窗口大小

data = []
curve = []
pen = ['b', 'r', 'g', 'k', 'c', 'b', 'r', 'g', 'k', 'c']  # 更多通道需要添加更多颜色
historyLength = 1000  # 横坐标长度
p = win.addPlot()  # 把图p加入到窗口中

p.showGrid(x=True, y=True)  # 把X和Y的表格打开
p.setRange(xRange=[0, historyLength], yRange=[1000, 2000], padding=0)
p.setLabel(axis='left', text='Velocity')  # 靠左
p.setLabel(axis='bottom', text='Point')
# p1.setTitle('Plot')#表格的名字

for i in range(channelNumber):
    data.append(array.array('d'))  # 可动态改变数组的大小,double型数组
    curve.append(p.plot())

Pre_speed = 0


def plotData():
    output = []
    global count
    count += 1
    global Pre_speed
    global motor
    signal_p = Arduino.readline()
    print(signal_p)
    signal_p = dataProcess(signal_p)
    # with open("0.5A echo flex.txt","a+") as f:
    #         f.writelines(str(signal_p[0])+'\n')
    if signal_p:
        if len(signal_p) == channelNumber:

            for i in range(channelNumber):
                if len(data[i]) < historyLength:
                    data[i].append(signal_p[i])
                else:
                    data[i][:-1] = data[i][1:]  # 前移
                    data[i][-1] = signal_p[i]
                curve[i].setData(data[i], pen=pg.mkPen(color=pen[i], width=3))


def canFloat(data):
    try:
        float(data)
        return True
    except:
        return False


def dataProcess(data):
    data = str(data)
    dataSet = []
    datapoint = ''
    for i in data:
        if i.isdigit() or i == '.':
            datapoint += i
        elif i == "," and canFloat(datapoint):
            dataSet.append(float(datapoint))
            datapoint = ''
    return dataSet


timer = pg.QtCore.QTimer()
# timer = Timer(0.001,plotData)
timer.timeout.connect(plotData)  # 定时调用plotData函数
timer.start(1)  # 多少ms调用一次
app.exec_()
