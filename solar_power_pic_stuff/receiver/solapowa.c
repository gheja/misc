#include <stdio.h>
#include <stdint.h>
#include <limits.h>

typedef struct pcap_file_header_s {
	uint32_t magic_number;
	uint16_t version_major;
	uint16_t version_minor;
	int32_t timezone;
	uint32_t sigfigs;
	uint32_t snaplen;
	uint32_t datalink;
} pcap_file_header_t;

typedef struct pcap_record_header_s {
	uint32_t timestamp_sec;
	uint32_t timestamp_usec;
	uint32_t bytes_saved;
	uint32_t bytes_original;
} pcap_record_header_t;

typedef struct x_header_s {
	uint8_t magic_number;
	uint8_t packet_type;
	uint8_t packet_version;
} x_header_t;

typedef struct x_dump_packet_s {
	uint8_t delay0;
	uint8_t delay1;

	uint8_t timer_interrupts;
	uint8_t timer_time_0;
	uint8_t timer_time_1;
	uint8_t timer_time_2;
	uint8_t timer_time_3;

	uint8_t wfi_interrupts;
	uint8_t wfi_loops_left;

	uint8_t ow_pd_byte; // presence detect (do we have anything on the wire?)
	uint8_t ow_bits_left;
	uint8_t ow_buffer;
	uint8_t ow_current_device_0;
	uint8_t ow_current_device_1;
	uint8_t ow_current_device_2;
	uint8_t ow_current_device_3;
	uint8_t ow_current_device_4;
	uint8_t ow_current_device_5;
	uint8_t ow_current_device_6;
	uint8_t ow_current_device_7;

	uint8_t thermo_in_msb;
	uint8_t thermo_in_lsb;
	uint8_t thermo_in_xsb;

	uint8_t thermo1_msb;
	uint8_t thermo1_lsb;
	uint8_t thermo1_xsb;
	uint8_t thermo2_msb;
	uint8_t thermo2_lsb;
	uint8_t thermo2_xsb;
	uint8_t thermo3_msb;
	uint8_t thermo3_lsb;
	uint8_t thermo3_xsb;
	uint8_t thermo4_msb;
	uint8_t thermo4_lsb;
	uint8_t thermo4_xsb;

	uint8_t spi_device_id;
	uint8_t spi_out_length;
	uint8_t spi_out_0;
	uint8_t spi_out_1;
	uint8_t spi_out_2;
	uint8_t spi_out_3;
	uint8_t spi_out_4;
	uint8_t spi_out_5;
	uint8_t spi_out_6;
	uint8_t spi_out_7;
	uint8_t spi_in;
	uint8_t spi_memory_start;
	uint8_t spi_checksum_0;
	uint8_t spi_checksum_1;
	uint8_t spi_options; //  xxxxxx10, 0: checksum calculation, 1: spi checksum byte selector
} x_dump_packet_t;

uint32_t conv4x8to32(uint8_t a, uint8_t b, uint8_t c, uint8_t d)
{
	return a * 256 * 256 * 256 + b * 256 * 256 + c * 256 + d;
}

float conv3x8tocelsius_ds1820(uint8_t msb, uint8_t lsb, uint8_t xsb)
{
	// temperature = temp_read - 0.25 + (count_per_c - count_remain) / count_per_c;
	float result = (msb * 256 + lsb) / 2.0 - 0.25 + (16 - xsb) / 16.0;
	
	if (result < -55.0 || result >= 85.0)
	{
		return 0.0;
	}
	
	return result;
}

float conv3x8tocelsius_ds18b20(uint8_t msb, uint8_t lsb, uint8_t xsb)
{
/*
	//
	// msb: aaaabbbb
	// lsb: ccccdddd
	// xsb: (none)
	//
	// new msb: 0000aaaa
	// new lsb: bbbbcccc
	// new xsb: dddd0000
	//
	return conv3x8tocelsius_ds1820((msb >> 4 & 0x0f), (msb << 4 & 0xf0) + (lsb >> 4 & 0x0f) , (lsb << 4 & 0xf0));
*/
	int sign = 1;
	
	if (msb & 7)
	{
		msb ^= 0xff;
		lsb ^= 0xff;
		sign = -1;
	}
	return ((msb >> 4 & 0x0f) * 256 + ((msb << 4 & 0xf0) + (lsb >> 4 & 0x0f)) + (lsb << 4 & 0xf0) / 256.0) * sign;
}

int main(int argc, const char* argv)
{
	FILE *f;
	pcap_file_header_t header;
	pcap_record_header_t header2;
	x_header_t x_header;
	x_dump_packet_t x_dump;
	unsigned int bytes_left;
	unsigned int packet_number;
	
	f = fopen("a.dmp", "rb");
	fread(&header, sizeof(header), 1, f);
	
	bytes_left = 0;
	packet_number = 0;
	while (1)
	{
		packet_number++;
		
		fseek(f, bytes_left, SEEK_CUR);
		
		if (!fread(&header2, sizeof(header2), 1, f))
		{
			break;
		}
		
		bytes_left = header2.bytes_saved;
		printf("%u.%06u packet #%d, starting at %d bytes, %d bytes long: ", header2.timestamp_sec, header2.timestamp_usec, packet_number, ftell(f), bytes_left);
		
		if (bytes_left < 70)
		{
			printf("packet is too short (skipping link and protocol headers), ignoring.\n");
			continue;
		}
		
		fseek(f, 70, SEEK_CUR);
		bytes_left -= 70;
		
		if (bytes_left < 48)
		{
			printf("packet is too short (skipping MAC, IP, UDP headers (part of dump)), ignoring.\n");
			continue;
		}
		
		fseek(f, 48, SEEK_CUR);
		bytes_left -= 48;
		
		if (bytes_left < sizeof(x_header))
		{
			printf("packet is too short (reading x_header), ignoring.\n");
			continue;
		}
		
		fread(&x_header, sizeof(x_header), 1, f);
		bytes_left -= sizeof(x_header);
		
		if (x_header.magic_number != 0x65)
		{
			printf("x_header.magic_number missmatch (wanted: 0x65, got 0x%02x), ignoring.\n", x_header.magic_number);
			continue;
		}
		
		if (x_header.packet_type != 1 || x_header.packet_version != 1)
		{
			printf("unsupported x_header.packet_type 0x%02x or x_header.packet_version 0x%02d, ignoring.\n", x_header.packet_type, x_header.packet_version);
			continue;
		}
		
		if (bytes_left < sizeof(x_dump))
		{
			printf("packet is too short (reading x_dump), ignoring.\n");
			continue;
		}
		
		fread(&x_dump, sizeof(x_dump), 1, f);
		bytes_left -= sizeof(x_dump);
		
		printf("packet read.\n");
		
		printf("\tSystem uptime:   %u seconds\n",
			conv4x8to32(x_dump.timer_time_0, x_dump.timer_time_1, x_dump.timer_time_2, x_dump.timer_time_3)
		);
		
		printf("\tT1 temperature:  %.2f 'C, %.2f 'C, 0x%02x%02x%02x\n",
			conv3x8tocelsius_ds1820(x_dump.thermo1_msb, x_dump.thermo1_lsb, x_dump.thermo1_xsb),
			conv3x8tocelsius_ds18b20(x_dump.thermo1_msb, x_dump.thermo1_lsb, x_dump.thermo1_xsb),
			x_dump.thermo1_msb,
			x_dump.thermo1_lsb,
			x_dump.thermo1_xsb
		);
		
		printf("\tT2 temperature:  %.2f 'C, %.2f 'C, 0x%02x%02x%02x\n",
			conv3x8tocelsius_ds1820(x_dump.thermo2_msb, x_dump.thermo2_lsb, x_dump.thermo2_xsb),
			conv3x8tocelsius_ds18b20(x_dump.thermo2_msb, x_dump.thermo2_lsb, x_dump.thermo2_xsb),
			x_dump.thermo2_msb,
			x_dump.thermo2_lsb,
			x_dump.thermo2_xsb
		);
		
		printf("\tT3 temperature:  %.2f 'C, %.2f 'C, 0x%02x%02x%02x\n",
			conv3x8tocelsius_ds1820(x_dump.thermo3_msb, x_dump.thermo3_lsb, x_dump.thermo3_xsb),
			conv3x8tocelsius_ds18b20(x_dump.thermo3_msb, x_dump.thermo3_lsb, x_dump.thermo3_xsb),
			x_dump.thermo3_msb,
			x_dump.thermo3_lsb,
			x_dump.thermo3_xsb
		);
		
		printf("\tT4 temperature:  %.2f 'C, %.2f 'C, 0x%02x%02x%02x\n",
			conv3x8tocelsius_ds1820(x_dump.thermo4_msb, x_dump.thermo4_lsb, x_dump.thermo4_xsb),
			conv3x8tocelsius_ds18b20(x_dump.thermo4_msb, x_dump.thermo4_lsb, x_dump.thermo4_xsb),
			x_dump.thermo4_msb,
			x_dump.thermo4_lsb,
			x_dump.thermo4_xsb
		);
		
		printf("\t--- debug ---\n");
		
		printf("\t1-wire device present:        %s\n",
			x_dump.ow_pd_byte ? "yes" : "no"
		);
		
		printf("\tLast 1-wire device detected:  0x%02x%02x%02x%02x%02x%02x%02x%02x\n",
			x_dump.ow_current_device_0,
			x_dump.ow_current_device_1,
			x_dump.ow_current_device_2,
			x_dump.ow_current_device_3,
			x_dump.ow_current_device_4,
			x_dump.ow_current_device_5,
			x_dump.ow_current_device_6,
			x_dump.ow_current_device_7
		);
		
		printf("\tLast temperature read:        %.2f 'C, %.2f 'C, 0x%02x%02x%02x\n",
			conv3x8tocelsius_ds1820(x_dump.thermo_in_msb, x_dump.thermo_in_lsb, x_dump.thermo_in_xsb),
			conv3x8tocelsius_ds18b20(x_dump.thermo_in_msb, x_dump.thermo_in_lsb, x_dump.thermo_in_xsb),
			x_dump.thermo_in_msb,
			x_dump.thermo_in_lsb,
			x_dump.thermo_in_xsb
		);
		
		
//		printf("\tUptime: %u seconds", conv4x8to32(x_dump.timer_time_0, x_dump.timer_time_1, x_dump.timer_time_2, x_dump.timer_time_3));
//		printf("\tUptime: %u seconds", conv4x8to32(x_dump.timer_time_0, x_dump.timer_time_1, x_dump.timer_time_2, x_dump.timer_time_3));
		
	}
	fclose(f);
	return 0;
}
