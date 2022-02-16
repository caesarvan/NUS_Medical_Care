"""
UART Service
-------------
An example showing how to write a simple program using the Nordic Semiconductor
(nRF) UART service.
"""
import xlwt
import asyncio
import struct
import sys
import pandas as pd

from datetime import datetime
from bleak import BleakScanner, BleakClient
from bleak.backends.scanner import AdvertisementData
from bleak.backends.device import BLEDevice

UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
UART_RX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
UART_TX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

# All BLE devices have MTU of at least 23. Subtracting 3 bytes overhead, we can
# safely send 20 bytes at a time to any device supporting this service.
UART_SAFE_SIZE = 20
# Creat an Excel Table
book = xlwt.Workbook()
sheet1 = book.add_sheet('sheet1')

# 数据长度规定
DataLength = 200  # 每一个动作的窗口长度
ChannelNumber = 8  # Arduino通道数量
DeleteNumber = 50  # 删除前几行数据点

row = 0
col = 0

async def uart_terminal():
    """This is a simple "terminal" program that uses the Nordic Semiconductor
    (nRF) UART service. It reads from stdin and sends each line of data to the
    remote device. Any data received from the device is printed to stdout.
    """

    def match_nus_uuid(device: BLEDevice, adv: AdvertisementData):
        # This assumes that the device includes the UART service UUID in the
        # advertising data. This test may need to be adjusted depending on the
        # actual advertising data supplied by the device.
        if UART_SERVICE_UUID.lower() in adv.service_uuids:
            return True

        return False

    device = await BleakScanner.find_device_by_filter(match_nus_uuid)

    def handle_disconnect(_: BleakClient):
        print("Device was disconnected, goodbye.")
        # cancelling all tasks effectively ends the program
        for task in asyncio.all_tasks():
            task.cancel()

    def handle_rx(_: int, data: bytearray):
        dataList = struct.unpack("!HHHHHHHH", data)
        timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
        print(timestamp, dataList)

        # 写入Excel
        # --------------------------------

        global col, row
        if row < DataLength * ChannelNumber:
            for i in range(ChannelNumber):
                sheet1.write(row, col, dataList[i])
                row += 1
            if row == DataLength * ChannelNumber:
                row = 0
                col += 1
                print("------------------Saved to csv------------------------")
                book.save('test.csv')

    async with BleakClient(device, disconnected_callback=handle_disconnect) as client:
        await client.start_notify(UART_TX_CHAR_UUID, handle_rx)

        print("Connected, start typing and press ENTER...")

        loop = asyncio.get_running_loop()

        while True:
            # This waits until you type a line and press ENTER.
            # A real terminal program might put stdin in raw mode so that things
            # like CTRL+C get passed to the remote device.
            data = await loop.run_in_executor(None, sys.stdin.buffer.readline)

            # data will be empty on EOF (e.g. CTRL+D on *nix)
            if not data:
                break

            # some devices, like devices running MicroPython, expect Windows
            # line endings (uncomment line below if needed)
            # data = data.replace(b"\n", b"\r\n")

            await client.write_gatt_char(UART_RX_CHAR_UUID, data)
            print("sent:", data)


if __name__ == "__main__":
    try:
        asyncio.run(uart_terminal())
    except asyncio.CancelledError:
        # task is cancelled on disconnect, so we ignore this error
        pass