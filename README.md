# NavQ95 EMC test software

## Description

This repository contains the EMC test software for the NavQ95 platform. The software is designed to exercise the onboard hardware components at high utilization levels, generating representative worst-case operating conditions to support Electromagnetic Compatibility (EMC) testing and validation.

## Installation

Obtain the SD-card image for the NavQ95 from [imx-manifest-navq95](https://github.com/NXP-Robotics/imx-manifest-navq95) by either building the yocto image yourself or by downloading one of the [releases](https://github.com/NXP-Robotics/imx-manifest-navq95/releases).

Write image to SD-card and boot the image and login as 'user' (password: 'user'). Run these commands on the A55 console to install the EMC test services:
```
git clone git@github.com:NXP-Robotics/navq95-emc-test.git
cd navq95-emc-test
sudo ./install.sh
```

## Prerequisites

External devices are required to execute the test software:

 - USB drives in J13 and J12
 - NVMe SSD in M2 Key M slot
 - External switch/AP
    - External switch connected to ethernet port on J8
    - WIFI AP with known SSID to the NavQ95 WIFI interface to
 - A CAN bus loopback wire that connect all NavQ95 CAN interfaces (J4, J8, J9 on the IO shield) to eachother without terminators

> **_NOTE:_**  USB drives, NVMe SSDs, and eMMC storage devices must be formatted with a filesystem supported by the NavQ95. The recommended filesystem is Ext4.

> **_NOTE:_**  The WIFI interface must be configured to connect to a wireless network. run ```sudo nmtui``` to attach to an SSID.

## Features

### Test services

A number of test services are available. All services are enabled and run simultaneously by default, but can be individually turned on or off as desired.
For a complete overview of the available services, see the services directory.

### Monitor

The test services are monitored for being active and the result is notified by the RGB LED on the NavQ95.

RGB LED status:

 - <span style="color:red">RED</span>: Some tests are not active
 - <span style="color:green">GREEN</span>: All tests are active
 - Any other color or LED off means the monitor is not active

### Additional device utilizations

Beside running the test services, several optional actions can be performed to further increase device utilization. These don't require test services to be started to enable them.

 - Apply SJA1110 loopback

   This method increases utilization of the SJA1110 network switch by connecting a loopback cable, causing transmitted traffic to be fed back into the switch. Broadcast messages are particularly impactful, as they can continuously circulate through the network and multiply, resulting in significantly increased traffic and switch utilization.

   The loopback can be inserted in two 100BASE-T1 ports or two 1000BASE-T1 ports.

   The PHY configuration of the SJA1110 firmware need to be adapted. One need to be configured as MASTER and the other as SLAVE.

 - Run Cognipilot/Cerebri on M7

   Running Cognipilot/Cerebri on the M7 core enables IMU sensor data acquisition, introducing additional processing load and increasing overall device utilization.

## Usage

Basic usage:

 - Power up the NavQ95
 - Wait for the LED to blink green

The tests can be turned on and off by using the systemd systemctl command.

Examples:
```
# stop emc-test-can.service
sudo systemctl stop emc-test-can.service

# start emc-test-can.service
sudo systemctl start emc-test-can.service
```

These tests are available:
 - emc-test-can.service
 - emc-test-emmc.service
 - emc-test-ethernet.service
 - emc-test-nvme.service
 - emc-test-sdcard.service
 - emc-test-usb1.service
 - emc-test-usb2.service
 - emc-test-wifi.service

The monitor service is called `emc-test-monitor.service`
