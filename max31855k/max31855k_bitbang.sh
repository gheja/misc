#!/bin/bash

#
# This is a script to get the current temperature in degrees Celsius from the
# MAX31855K "Cold-Junction Compensated Thermocouple-to-Digital Converter" IC
#
# It does not use the SPI hardware and/or kernel module but bitbanging (that is
# manually setting the bits on each GPIO pins) so can be used on any three GPIO
# pin of the Raspberry PI (or any other GPIO equipped hardware, probably).
#
# It does some sanity check on the retrieved data, but:
# PLEASE NOTE: negative temperature values are NOT YET handled!
#
# Pins used in this example (configurable, see below):
#   - CE (chip enable): GPIO08
#   - SCK (serial clock): GPIO11
#   - MISO (master in slave out): GPIO09
#   - MOSI (master out slave in): not connected
#
# Datasheet:
#   - https://cdn.sparkfun.com/datasheets/Sensors/Temp/MAX31855K.pdf
#   - https://www.adafruit.com/datasheets/MAX31855.pdf
#
# SparkFun breakout board:
#   - https://www.sparkfun.com/products/13266
#
# You are free to use this script in any ways you want.
#
# https://github.com/gheja/misc
#

spi_ce=8
spi_sck=11
spi_miso=9

if [ ! -e /sys/class/gpio/gpio${spi_ce} ]; then
	echo "$spi_ce" > /sys/class/gpio/export
fi

if [ ! -e /sys/class/gpio/gpio${spi_sck} ]; then
	echo "$spi_sck" > /sys/class/gpio/export
fi

if [ ! -e /sys/class/gpio/gpio${spi_miso} ]; then
	echo "$spi_miso" > /sys/class/gpio/export
fi

echo "out" > /sys/class/gpio/gpio${spi_ce}/direction
echo "out" > /sys/class/gpio/gpio${spi_sck}/direction
echo "in" > /sys/class/gpio/gpio${spi_miso}/direction

# de-select device (initiate temperature measurement)
echo 1 > /sys/class/gpio/gpio${spi_ce}/value

# wait for temperature measurement to complete
sleep 0.25

# select device
echo 0 > /sys/class/gpio/gpio${spi_ce}/value

# read the 32 bit data
bits=""
i=0
while [ $i -lt 32 ]; do
	
	echo 0 > /sys/class/gpio/gpio${spi_sck}/value
	echo 1 > /sys/class/gpio/gpio${spi_sck}/value
	value=`cat /sys/class/gpio/gpio${spi_miso}/value`
	
	bits="${bits}${value}"
	
	i=$((i + 1))
done

# de-select device
echo 1 > /sys/class/gpio/gpio${spi_ce}/value

# 00000001101011000001110110000000
# 12345678901234567890123456789012
# aaaaaaaaaaaaaabcddddddddddddefgh

# a: D31..18 thermocouple temperature data (14 bits)
# b: D17     reserved (always 0)
# c: D16     fault (any failure) (1 on failure)
# d: D15..4  internal temperature data (12 bits)
# e: D3      reserved (always 0)
# f: D2      SCV fail (thermocouple short circuit to VCC) (1 on failure)
# g: D1      SCG fail (thermocouple short circuit to GND) (1 on failure)
# h: D0      OC fail (thermocouple not connected) (1 on failure)

thermocouple=${bits:0:14}
reserved1=${bits:14:1}
fault_any=${bits:15:1}
internal=${bits:16:12}
reserved2=${bits:28:1}
fault_scv=${bits:29:1}
fault_scg=${bits:30:1}
fault_oc=${bits:31:1}

# echo "$bits"
# echo "aaaaaaaaaaaaaabcddddddddddddefgh"
# echo "$thermocouple, $reserved1, $fault_any, $internal, $reserved2, $fault_scv, $fault_scg, $fault_oc"

if [ $reserved1 != 0 ]; then
	echo "Error: \"reserved 1\" (D17) is not 0"
	exit 1
fi

if [ $reserved2 != 0 ]; then
	echo "Error: \"reserved 2\" (D3) is not 0"
	exit 1
fi

if [ $fault_scv != 0 ]; then
	echo "Error: thermocouple short-circuited to VCC (D2 == 1)"
	exit 1
fi

if [ $fault_scg != 0 ]; then
	echo "Error: thermocouple short-circuited to GND (D1 == 1)"
	exit 1
fi

if [ $fault_oc != 0 ]; then
	echo "Error: thermocouple not connected (D0 == 1)"
	exit 1
fi

if [ $fault_any != 0 ]; then
	echo "Error: chip returned an unknown error (D17 == 1)"
	exit 1
fi

if [ ${thermocouple:0:1} == 1 ]; then
	echo "Error: negative temperature values are not yet supportred (D31 == 1)"
	exit 1
fi

i=1
value=0
tmp=1024
while [ $i -lt 12 ]; do
	if [ ${thermocouple:$i:1} == 1 ]; then
		value=$((value + tmp))
	fi
	
	tmp=$((tmp / 2))
	i=$((i + 1))
done

fraction=0

if [ ${thermocouple:12:1} == 1 ]; then
	fraction=$((fraction + 50))
fi

if [ ${thermocouple:13:1} == 1 ]; then
	fraction=$((fraction + 25))
fi

echo "${value}.${fraction}"

exit 0
