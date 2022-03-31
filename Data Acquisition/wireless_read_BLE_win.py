import array
import struct
import time
import csv
import xlwt
import asyncio
import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtGui
from bleak import BleakClient
from qasync import QEventLoop
from datetime import datetime
import winsound
import os
# ESP32 ID format for Mac
# Different format for PC

address = "D7:C8:10:07:76:7A"
# 60DB0570-32CE-4B00-B901-29DAE5DE79AA   EE5003666
# 8DBDB0F9-1360-44CF-899A-F8F5ADB8AA56   EE5003
UART_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"  # ?????????uuid
UART_RX_CHAR_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

length_window = 200
channelNumber = 16
pen = ['b', 'r', 'g', 'k', 'c', 'b', 'r', 'g', 'k', 'c','b', 'r', 'g', 'k', 'c', 'b', 'r', 'g', 'k', 'c']
jump_data=500

class BleakScanner:
    pass

class Window(pg.GraphicsLayoutWidget):  # ????
    dataLine=[]
    def __init__(self, loop=None, parent=None):
        super().__init__(parent)
        self._loop = loop

        self.setWindowTitle("pyqtgraph example: Scrolling Plots")
        self.setBackground('w')

        plot1 = self.addPlot(title="data")
        plot1.addLegend()

        plot1.setRange(xRange=[0, length_window], yRange=[1000, 2000], padding=0)

        self._save_data = []
        self._curve = []
        for i in range(channelNumber):
            self._save_data.append(array.array('d'))  # ??????????,double???
            self._curve.append(plot1.plot())
        self._client = BleakClient(address, loop=self._loop)

    @property
    def client(self):
        return self._client

    async def start(self):
        await self.client.connect()
        self.start_read()

    async def stop(self):
        await self.self.disable_notif()

    async def read(self):

        await self.client.start_notify(UART_RX_CHAR_UUID, self.notification_handler)

        await asyncio.sleep(46.0)

        await self.client.stop_notify(UART_RX_CHAR_UUID)

        QtCore.QTimer.singleShot(100, self.start_read)

    def notification_handler(self, _: int, data: bytearray):
        global dataLine, dataBatch, row,datalength,jump_data
        # measurement = int(data) / 100
        # current_time = time.time()
        # for_log = [current_time, sender, measurement]
        # print(for_log)
        # self.log_data(for_log)
        dataList = struct.unpack("!hhhhhhhhhhhhhhhh", data)

        timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
        # print(timestamp, dataList)
        jump_data-=1
        if(jump_data<0):
            self.dataLine.extend(list(dataList))
            print(len(self.dataLine), timestamp, dataList)
            if len(self.dataLine) == length_window * channelNumber:
                with open('dataset/testtest.csv', 'a', newline='') as table:
                    writer = csv.writer(table)
                    writer.writerow(self.dataLine)
                    table.close()
                self.dataLine = []
                winsound.PlaySound("sounds/start.aiff", winsound.SND_ASYNC)
                jump_data=200
            # os.system("pause")
            # pause 2 sec


        # print(dataList)
        for i in range(channelNumber):
            if len(self._save_data[i]) < length_window:
                self._save_data[i].append(dataList[i])
            else:
                self._save_data[i][:-1] = self._save_data[i][1:]  # ??
                self._save_data[i][-1] = dataList[i]
            self._curve[i].setData(self._save_data[i], pen=pg.mkPen(color=pen[i], width=3))

    def start_read(self):
        asyncio.ensure_future(self.read(), loop=self._loop)


def main(args):
    app = QtGui.QApplication(args)
    loop = QEventLoop(app)
    asyncio.set_event_loop(loop)

    window = Window()
    window.show()

    with loop:
        asyncio.ensure_future(window.start(), loop=loop)
        loop.run_forever()


if __name__ == "__main__":
    import sys

    main(sys.argv)
