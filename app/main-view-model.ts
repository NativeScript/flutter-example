import { Observable, Utils } from "@nativescript/core";
import { Bluetooth, Peripheral } from "@nativescript-community/ble";
import { Flutter, FlutterChannelType } from "@nativescript/flutter";

export class HelloWorldModel extends Observable {
  flutter: Flutter;
  channel: FlutterChannelType;
	bluetooth: Bluetooth;
	discoveredPeripherals: Array<{ name: string; address: string }>;
	throttleScanResults: () => void;

  constructor() {
    super();
    this.bluetooth = new Bluetooth();
		this.channel = {
			startScanning: this._startScanning.bind(this),
			stopScanning: this._stopScanning.bind(this),
		};
		// reduce extraneous bluetooth scan results when emitting to Flutter
		this.throttleScanResults = Utils.throttle(this._throttleScanResults.bind(this), 600);
  }

  private _throttleScanResults() {
		if (this.flutter) {
			this.flutter.sendMessage('scanResults', this.discoveredPeripherals);
		}
	}

	private _stopScanning() {
		if (this.bluetooth) {
			this.bluetooth.stopScanning();
			this.bluetooth.off(Bluetooth.device_discovered_event);
			this.flutter.sendMessage('stoppedScanning');
		}
	}

	private _startScanning() {
		this.bluetooth.on(Bluetooth.device_discovered_event, (result: any) => {
			const peripheral = <Peripheral>result.data;
			if (peripheral) {
				if (!this.discoveredPeripherals) {
					this.discoveredPeripherals = [];
				}
				if (peripheral.name) {
					if (!this.discoveredPeripherals.find((p) => p.address === peripheral.UUID)) {
						this.discoveredPeripherals.push({
							name: peripheral.name.trim(),
							address: peripheral.UUID?.trim(),
						});
					}
					this.throttleScanResults();
				}
			}
		});
		this.bluetooth.startScanning({});
	}
}
