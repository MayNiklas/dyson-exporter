import time

import libdyson
from libdyson import get_mqtt_info_from_wifi_info
from libdyson.exceptions import DysonFailedToParseWifiInfo


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


if __name__ == '__main__':
    dyson_ip = ""
    dyson_ssid = ""
    dyson_ssid_password = ""

    serial, credential, device_type = calculate_creds(dyson_ssid, dyson_ssid_password)

    while (1 == 1):
        result = (get_dyson_readings(dyson_ip, serial, credential, device_type))
        print(kelvinToCelsius(result["temperature"]))
        time.sleep(5)
