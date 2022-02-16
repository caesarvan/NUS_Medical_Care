import os
os.environ['KERAS_BACKEND'] = 'tensorflow'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import numpy as np
import serial
import xlwt
import winsound
import time
from sklearn.externals import joblib
import matplotlib.pyplot as plt
from keras.models import load_model
# import sys
# import tty
# import termios

plt.ion() #开启绘图交互
book = xlwt.Workbook()  # 创建一个Excel
sheet1 = book.add_sheet('sheet1')
x = 0
y = 0



def canStr(aString):
    try:
        float(aString)
        return True
    except:
        return False

def dataRead():
        dataSet = []
        data = serial_.readline()
        data = str(data)
        if (DataCollectionFlag == True):
            datapoint = ''
            for i in data:
                if i.isdigit() or i == '.':
                    datapoint += i
                elif i == ',' and canStr(datapoint):
                    global x
                    datapoint = float(datapoint)
                    sheet1.write(x, y, datapoint)
                    PredictData.append(datapoint)
                    dataSet.append(datapoint)
                    x += 1
                    datapoint = ''
            print(dataSet)

# def readchar():
#     fd = sys.stdin.fileno()
#     old_settings = termios.tcgetattr(fd)
#     try:
#         tty.setraw(sys.stdin.fileno())
#         ch = sys.stdin.read(1)
#     finally:
#         termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
#     return ch
#
#
# def readkey(getchar_fn=None):
#     getchar = getchar_fn or readchar
#     c1 = getchar()
#     if ord(c1) != 0x1b:
#         return c1
#     c2 = getchar()
#     if ord(c2) != 0x5b:
#         return c1
#     c3 = getchar()
#     return chr(0x10 + ord(c3) - 65)


while True:
    DataCollectionFlag = False
    plt.cla()
    PredictData = []
    print("Motion Number: ",y)
    print("Please Grap Objects")
    # time.sleep(1)
    serial_ = serial.Serial("COM3", 115200)   # /dev/ttyUSB0   #采数据才打开串口
    DataLength = 200                          #每一个动作的窗口长度
    ChannelNumber = 10                         #Arduino通道数量
    DeleteNumber = 50                           #删除前几行数据点
    # winsound.PlaySound('Audio/Go_Re.wav', winsound.SND_ASYNC)
    for i in range(DataLength+DeleteNumber):  # 每一次动作采集的数据点，前DeleteNumber行抛弃
        if(i == DeleteNumber):
            DataCollectionFlag = True
        dataRead()
        if i == DataLength+DeleteNumber-1:
            print("Data Collection Completed")
    # print(PredictData)
    serial_.close()         #关闭串口
    # winsound.PlaySound('Audio/alarm.wav', winsound.SND_ASYNC)
    print("Data Length:",len(PredictData))
    if (len(PredictData) != DataLength*ChannelNumber):
        print("Error In Data")
        print("--------------------------------------------------------------------------")
        book.save('Error.xlsx')  # 每个手势换一个文件名,每运行一次都会覆盖
        y += 1
        x = 0
        continue
    else:
        PredictData = np.array(PredictData)

        print("---------------------------------------------------------------------------")
        book.save('./boom.csv')  # 每个手势换一个文件名,每运行一次都会覆盖
        y += 1
        x = 0
    time.sleep(2)




