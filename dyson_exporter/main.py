import os
import time

import libdyson
from libdyson import get_mqtt_info_from_wifi_info
from libdyson.exceptions import DysonFailedToParseWifiInfo
from prometheus_client import start_http_server, Gauge

# metrics
dyson_temperature = Gauge('dyson_temperature', 'current temperature measured by Dyson')
dyson_humidity = Gauge('dyson_humidity', 'current humidity measured by Dyson')


def kelvinToCelsius(kelvin):
    if kelvin != -1:
        return kelvin - 273.15
    else:
        return 0


def calculate_creds(wifi_ssid, wifi_password):
    """
    Calculate device credential using WiFi information.
    Source: https://github.com/shenxn/libdyson/blob/main/calculate_device_credenial.py
    """

    try:
        serial, credential, device_type = get_mqtt_info_from_wifi_info(
            wifi_ssid, wifi_password
        )
    except DysonFailedToParseWifiInfo:
        print("Failed to parse SSID.")

    return serial, credential, device_type


def get_dyson_readings(ip: str, dyson_username: str, dyson_password: str,
                       dyson_type: libdyson.dyson_device) -> dict:
    device = libdyson.get_device(serial=dyson_username,
                                 credential=dyson_password,
                                 device_type=dyson_type)
    device.connect(host=ip)

    readings = {
        "temperature": device.temperature,
        "humidity": device.humidity,
    }

    device.disconnect()
    return readings


def main():
    
    dyson_ip = os.environ.get("dyson_ip")
    dyson_ssid = os.environ.get("dyson_ssid")
    dyson_ssid_password = os.environ.get("dyson_ssid_password")
    dyson_exporter_listen=os.environ.get("dyson_exporter_listen")
    dyson_exporter_port=os.environ.get("dyson_exporter_port")

    serial, credential, device_type = calculate_creds(dyson_ssid, dyson_ssid_password)

    # Start up the server to expose the metrics.
    start_http_server(int(dyson_exporter_port), addr=dyson_exporter_listen)

    while 1 == 1:
        measurements = get_dyson_readings(dyson_ip, serial, credential, device_type)
        if kelvinToCelsius(measurements["temperature"]) != 0:
            dyson_temperature.set(kelvinToCelsius(measurements["temperature"]))
            dyson_humidity.set(measurements["humidity"])

        time.sleep(15)


if __name__ == '__main__':
    main()
