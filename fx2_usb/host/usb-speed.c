#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <usb.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

// compile with gcc -Wall -lusb -o usb_rd usb_rd.c

static usb_dev_handle *handle;

#define USB_VENDOR_ID 0x4711
#define USB_PRODUCT_ID 0x0023

struct usb_device *find_device()
{
	struct usb_bus *bus;
	struct usb_device *dev;

	usb_find_busses();
	usb_find_devices();

	for (bus = usb_get_busses(); bus; bus = bus->next) {
		for (dev = bus->devices; dev; dev = dev->next) {
			if (dev->descriptor.idVendor == USB_VENDOR_ID &&
			    dev->descriptor.idProduct == USB_PRODUCT_ID)
				// Found it
				return dev;
		}
	}

	return NULL;
}

int init(void)
{
	struct usb_device *dev;

	dev = find_device();
	if (dev == NULL) {
		printf("not found\n");
		goto cleanup;
	}

	handle = usb_open(dev);
	if (handle == NULL)
		goto cleanup;

	usb_detach_kernel_driver_np(handle, 0);

	if (usb_set_configuration(handle, 1) < 0)
		goto cleanup;

	if (usb_claim_interface(handle, 0) < 0)
		goto cleanup;

//if (usb_set_altinterface(handle, 2) < 0)
	//goto cleanup;

	return 0;

 cleanup:
	assert(0);

	return 0;
}

void hexdump(unsigned char *d, int len)
{
	while (len--) {
		printf("%02x ", *d);
		d++;
	}
}

int main(int argc, char **argv)
{
	unsigned char *response;
	int ret;
	int cnt;
	int last=0xff;
	time_t start, end;

	usb_init();
	init();
	
	assert((response = malloc(1024*1024*1024)));

	start=time(NULL);
	ret = usb_bulk_read(handle, 0x86, (char*)response, 1024*1024*1024, 100000);
	end =time(NULL);
	
	assert(ret == (1024*1024*1024));
	
	printf("speed: %ld MB/s\n",1024/(end-start));
	
	return 0;
}
