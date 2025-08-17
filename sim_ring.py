#!/usr/bin/env python3
"""
SafetyRing BLE Simulator - Windows-friendly version

This script simulates a BLE peripheral device named "SafetyRing" that can be used
to test the iOS SafetyRing app. It advertises the Alert Notification Service (0x1811)
and sends "ALERT" notifications via the New Alert characteristic (0x2A46).

Windows users: Use nRF Connect app on Android instead of this Python script.
Linux/macOS users: Run this script directly.

Requirements:
- bleak>=0.22 (Linux/macOS only)
- asyncio
"""

import asyncio
import sys
import platform

# Platform detection
IS_WINDOWS = platform.system() == "Windows"

if IS_WINDOWS:
    print("=" * 60)
    print("SAFETYRING BLE SIMULATOR - WINDOWS DETECTED")
    print("=" * 60)
    print()
    print("Windows doesn't support BLE peripheral simulation with bleak.")
    print("Use one of these alternatives instead:")
    print()
    print("OPTION 1 (Recommended): Android + nRF Connect")
    print("1. Install 'nRF Connect' from Google Play Store")
    print("2. Open nRF Connect → 'Advertiser' tab")
    print("3. Configure:")
    print("   - Name: SafetyRing")
    print("   - Service: Alert Notification (0x1811)")
    print("   - Characteristic: New Alert (0x2A46)")
    print("   - Properties: Notify")
    print("4. Start advertising")
    print("5. In nRF Connect → 'Scanner' → find your device → connect")
    print("6. Send notification with value: 'ALERT'")
    print()
    print("OPTION 2: Use another Windows BLE tool")
    print("- BLE Scanner (Windows Store)")
    print("- Bluetooth LE Explorer")
    print()
    print("OPTION 3: Linux/macOS with this script")
    print("- Run on a Linux/macOS machine")
    print("- Install: pip install bleak>=0.22")
    print("- Execute: python3 sim_ring.py")
    print()
    print("=" * 60)
    sys.exit(0)

# Linux/macOS implementation
try:
    from bleak import BleakGATTCharacteristic, BleakGATTService, BleakGATTSimulatorServer
except ImportError:
    print("Error: bleak>=0.22 required for BLE simulation")
    print("Install with: pip install bleak>=0.22")
    sys.exit(1)

# BLE Service and Characteristic UUIDs
ALERT_NOTIFICATION_SERVICE = "00001811-0000-1000-8000-00805f9b34fb"  # 0x1811
NEW_ALERT_CHAR = "00002a46-0000-1000-8000-00805f9b34fb"  # 0x2A46 (Notify)

async def main():
    """Main function to run the BLE simulator"""
    print("🚨 SafetyRing BLE Simulator Starting...")
    print("=" * 50)
    
    # Create GATT service and characteristic
    service = BleakGATTService(ALERT_NOTIFICATION_SERVICE)
    new_alert = BleakGATTCharacteristic(NEW_ALERT_CHAR, ["notify"])
    service.add_characteristic(new_alert)
    
    # Create and start the BLE server
    server = BleakGATTSimulatorServer(
        device_name="SafetyRing",
        services=[service],
        advertise_services=[ALERT_NOTIFICATION_SERVICE],
    )
    
    try:
        await server.start()
        print("✅ Advertising as 'SafetyRing'")
        print("📱 Your iOS app should now detect this device")
        print("🔔 Press Enter to send ALERT notification")
        print("⏹️  Press Ctrl+C to stop")
        print("=" * 50)
        
        # Main loop for sending alerts
        while True:
            try:
                # Wait for Enter key
                await asyncio.get_event_loop().run_in_executor(None, input)
                
                # Send ALERT notification
                payload = b"ALERT"
                print(f"🚨 Sending notification: {payload.decode()}")
                await server.notify(NEW_ALERT_CHAR, payload)
                print("✅ Notification sent! Check your iOS app")
                print("-" * 30)
                
            except EOFError:
                # Handle Ctrl+D
                break
                
    except KeyboardInterrupt:
        print("\n⏹️  Stopping simulator...")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        await server.stop()
        print("✅ Simulator stopped")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        sys.exit(1)


