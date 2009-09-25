#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <usb.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

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
	unsigned char buf[1024*2];
	int ret, res;

	usb_init();
	init();

	ret = usb_bulk_read(handle, 0x86, buf, 1024*2, 100);
	
	while(1) {
		read(0,buf,1024);
		ret = usb_bulk_write(handle, 0x02, buf, 1024,100);
		if(ret != 1024)
			printf("s %d ",ret);
		ret = usb_bulk_read(handle, 0x86, buf+1024, 1024, 100);
		res=memcmp(buf,buf+1024,1024);
		if((ret != 1024) || (res))
			printf("r %d cmp %d\n",ret,res);
		//fprintf(stderr,"%d\n",ret);
		//if(ret>0) {
		if(res!=0) {
			hexdump(buf,16);
			printf("| ");
			hexdump(buf+1024,16);
			printf("\n");
			//fflush(stdout);
			//write(1,response,ret);
		}
	}

	return 0;
}
