Just committed this as is.

This is just a stub, it needs a lot of comments and cleanups, but might come handy later...

This is a PIC 16F877A based project, it was intended to be a solar panel
controller with dual power source (solar panel and an ATX power supply),
with the capability of reading the input voltages, switching the sources
for the output and reading more thermal sensors and sending the whole
collected bunch of data over UDP to a PC.

It basically does the following:
  * reads four Dallas 1-wire thermometers (DS1820 or DS18B20),
  * stores their readings in memory,
  * communicates via an Ethernet module (over SPI),
  * compiles an UDP packet (actually the RAM is structured to be a valid UDP packet when dumped, he-he),
  * sends it over the network.

It is also possible to detect a device over the 1-wire bus.

There is the receiver, too which reads tcpdump packets.

I have commited everything I have including compiled and intermediate files.

For PIC programming I used the Microchip MPLAB IDE (on Windows), for the receiver I used gcc (on Linux).



(Sorry for the "solapowa" thing...)
