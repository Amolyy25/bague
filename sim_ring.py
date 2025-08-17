import asyncio
import sys

# Note: bleak currently supports Peripheral role via experimental backends on Linux/macOS.
# Windows peripheral role is not supported. Use Linux/macOS for this simulator.

try:
    from bleak import BleakGATTCharacteristic
    from bleak import BleakGATTService
    from bleak import BleakGATTSimulatorServer
except Exception as e:
    print("This simulator requires bleak experimental GATT server support.")
    print("Install via: pip install bleak>=0.22")
    print("Run on Linux/macOS. Windows peripheral role is not supported.")
    sys.exit(1)


ALERT_NOTIFICATION_SERVICE = "00001811-0000-1000-8000-00805f9b34fb"  # 0x1811
NEW_ALERT_CHAR = "00002a46-0000-1000-8000-00805f9b34fb"  # 0x2A46 (Notify)


async def main():
    print("Starting SafetyRing BLE simulator...")

    service = BleakGATTService(ALERT_NOTIFICATION_SERVICE)
    new_alert = BleakGATTCharacteristic(NEW_ALERT_CHAR, ["notify"])
    service.add_characteristic(new_alert)

    server = BleakGATTSimulatorServer(
        device_name="SafetyRing",
        services=[service],
        advertise_services=[ALERT_NOTIFICATION_SERVICE],
    )

    await server.start()
    print("Advertising as 'SafetyRing'. Press Enter to emit ALERT notification. Ctrl+C to exit.")

    try:
        while True:
            await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            payload = b"ALERT"
            print("Sending notification: ALERT")
            await server.notify(NEW_ALERT_CHAR, payload)
    except KeyboardInterrupt:
        pass
    finally:
        await server.stop()
        print("Simulator stopped")


if __name__ == "__main__":
    asyncio.run(main())


