/*-----------------------------------------------------------------------------
 * Copyright (C) 2008 Benedikt Heinz, 2005..2007 Kolja Waschk, ixo.de
 *-----------------------------------------------------------------------------
 * This code is partially based on usbjtag. 
 * This code is free software; you can redistribute
 * it and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version. usbjtag is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.  You should have received a
 * copy of the GNU General Public License along with this program in the file
 * COPYING; if not, write to the Free Software Foundation, Inc., 51 Franklin
 * St, Fifth Floor, Boston, MA  02110-1301  USA
 *-----------------------------------------------------------------------------
 */

#include "isr.h"
#include "timer.h"
#include "delay.h"
#include "fx2regs.h"
#include "fx2utils.h"
#include "usb_common.h"
#include "usb_descriptors.h"
#include "usb_requests.h"

#include "syncdelay.h"

extern unsigned char _usb_config;

// mosfet for power enable
#define USB_ON	(1<<7) // PD7

// VCC3V3 detect
#define VCC3V3_OK	(1<<1) // PA1

/* jtag pins:
 * tdo - pin 0 (input)
 * tdi - pin 2 (output)
 * tms - pin 3 (output)
 * tck - pin 4 (output)
 */
#define 	TDI_		(1<<2)
#define	TDO_		(1<<0)
#define	TCK_		(1<<4)
#define	TMS_		(1<<3)

#define	CMD_JTAG_TMS		0x20
#define	CMD_JTAG_LAST		0x04
#define	CMD_JTAG_TDO		0x02

typedef BYTE u8;
typedef WORD u16;

// TODO: enable only during actual programming!
void jtag_init(u8 enable) {

	if(enable) {
		
		/* pin 5 of port d disables tdi -> tdo forward */
		OED|=(1<<5); // TODO
		IOD|=(1<<5);

		/* set JTAG in/outputs */
		OED |= (TDI_ | TCK_ | TMS_);
		OED &= ~TDO_;

		/* set them low */
		IOD &= ~(TCK_ | TMS_ | TDI_);
		
	}
	else {
		// disable jtag output
		OED = USB_ON;
		IOD &= USB_ON;
	}
}

void set_tms(u8 val) {
	if(val)
		IOD|= TMS_;
	else
		IOD&= ~TMS_;
}

#define set_tdi(a)		IOD&= ~TDI_; IOD|=(a)<<2;
#define set_tck(a)		IOD&= ~TCK_; IOD|=(a)<<4;
#define tck_cycle()		set_tck(1); set_tck(0)

sbit at 0xB4          TCK;
#define bmTCKOE       bmBIT4
#define SetTCK(x)     do{TCK=(x);}while(0)
 
/* JTAG TDI, AS ASDI, PS DATA0 */
 
sbit at 0xB2          TDI;
#define bmTDIOE       bmBIT2
#define SetTDI(x)     do{TDI=(x);}while(0)
 
/* JTAG TMS, AS/PS nCONFIG */
sbit at 0xB3          TMS;
#define bmTMSOE       bmBIT3
#define SetTMS(x)     do{TMS=(x);}while(0)
 
/* JTAG TDO, AS/PS CONF_DONE */
 
sbit at 0xB0          TDO;
#define bmTDOOE       bmBIT0
#define GetTDO(x)     TDO

void ProgIO_ShiftOut(unsigned char c)
{
  /* Shift out byte C:
   *
   * 8x {
   *   Output least significant bit on TDI
   *   Raise TCK
   *   Shift c right
   *   Lower TCK
   * }
   */
 
  (void)c; /* argument passed in DPL */
 
  _asm
        MOV  A,DPL
        ;; Bit0
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        ;; Bit1
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit2
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit3
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit4
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit5
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit6
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
        ;; Bit7
        RRC  A
        CLR  _TCK
        MOV  _TDI,C
        SETB _TCK
	nop
        CLR  _TCK
        ret
  _endasm;
}
 
/*
;; For ShiftInOut, the timing is a little more
;; critical because we have to read _TDO/shift/set _TDI
;; when _TCK is low. But 20% duty cycle at 48/4/5 MHz
;; is just like 50% at 6 Mhz, and that's still acceptable
*/
 
unsigned char ProgIO_ShiftInOut(unsigned char c)
{
  /* Shift out byte C, shift in from TDO:
   *
   * 8x {
  *   Read carry from TDO
   *   Output least significant bit on TDI
   *   Raise TCK
   *   Shift c right, append carry (TDO) at left
   *   Lower TCK
   * }
   * Return c.
   */
 
   (void)c; /* argument passed in DPL */
 
  _asm
        MOV  A,DPL
 
        ;; Bit0
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit1
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit2
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit3
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit4
       MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit5
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit6
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK
        ;; Bit7
        MOV  C,_TDO
        RRC  A
        MOV  _TDI,C
        SETB _TCK
        CLR  _TCK

        MOV  DPL,A
        ret
  _endasm;
 
  /* return value in DPL */
 
  return c;
}

u8 handle_jtag(void) {	
	u16 bitlen = ( (EP1OUTBUF[0] & 1) << 8) | EP1OUTBUF[1];
	u8 bytecnt, byte, bitcnt;
		
	EP1INBUF[0] = EP1OUTBUF[0];
	EP1INBUF[1] = EP1OUTBUF[1];
	
	// TMS
	if(EP1OUTBUF[0] & CMD_JTAG_TMS) {
				
		for(bytecnt=0; bitlen; bytecnt++) {
			byte = EP1OUTBUF[2+bytecnt];
			
			// copy
			EP1INBUF[2+bytecnt] = byte;
			
			for(bitcnt=0; (bitlen) && (bitcnt<8); bitcnt++, bitlen--) {
				set_tms(byte&1);
				byte>>=1;
				
				tck_cycle();
			} // foreach bit
			
		} // foreach byte
		
	}

	// TDI only
	else if (!(EP1OUTBUF[0] & CMD_JTAG_TDO)) {
		
		if (EP1OUTBUF[0] & CMD_JTAG_LAST)
			bitlen--;
		
		bytecnt = bitlen/8;
		byte=2;
		
		while(bytecnt--)
			ProgIO_ShiftOut(EP1OUTBUF[byte++]);
		
		if (EP1OUTBUF[0] & CMD_JTAG_LAST)
			bitlen++;
		
		bitlen -= ((byte-2)*8);
		byte=EP1OUTBUF[byte];
		
		while(bitlen--) {
			
			if((!bitlen) && (EP1OUTBUF[0] & CMD_JTAG_LAST))
				set_tms(1);
			
			IOD &= ~TDI_;
			IOD |= (byte & 1)<<2;
			
			byte >>= 1;
			
			tck_cycle();
		}
	}
	
	// TDI/TDO
	else {
		u8 obyte;
		
		for(bytecnt=0; bitlen; bytecnt++) {
			byte = EP1OUTBUF[2+bytecnt];
			obyte=0;
			
			for(bitcnt=0; (bitlen) && (bitcnt<8); bitcnt++) {
				
				bitlen--;
				
				/* last one */
				if((!bitlen) && (EP1OUTBUF[0] & CMD_JTAG_LAST))
					set_tms(1);
				
				IOD&= ~TDI_;
				IOD |= (byte&1)<<2;
				
				byte>>=1;
				
				obyte |= (IOD & TDO_) << bitcnt;
				
				tck_cycle();
			} // foreach bit
		
			EP1INBUF[2+bytecnt] = obyte;
			
		} // foreach byte
			
	} // TDI/TDO
	
	return (EP1OUTBUF[0] & CMD_JTAG_TDO) ? 64 : 0;
	//return 64;
}

void usb_ep1_init (void){

	EP1INCFG = 0xa0;	/*  bulk EP, enable */
	EP1OUTCFG = 0xa0;       /*  bulk EP, enable */

//	EXIF &= ~0x10;
//	EPIRQ = 0x0c;		/*  clear pending irqs */
//	EPIE |= 0x0c;		/*  enable EP1 in+out irq */


	SYNCDELAY;
	EP1OUTBC = 0;	   /*  arm EP1out */
	SYNCDELAY;
}

void usb_ep1_process_request (void){
	u8 retlen = 0;

	if ((EP01STAT & 0x06) != 0x00)	/* still busy? */
		return;

	retlen = handle_jtag();	
		
	SYNCDELAY;
	EP1OUTBC = 0;		/*  re-arm EP1out */
	SYNCDELAY;

	if(retlen) {
		SYNCDELAY;
		EP1INBC = retlen;
		SYNCDELAY;
	}

}

void nexys_init(void)              // Called once at startup
{
   WORD tmp;

   // Make Timer2 reload at 100 Hz to trigger Keepalive packets

   tmp = 65536 - ( 48000000 / 12 / 100 );
   RCAP2H = tmp >> 8;
   RCAP2L = tmp & 0xFF;
   CKCON = 0; // Default Clock
   T2CON = 0x04; // Auto-reload mode using internal clock, no baud clock.

   // Enable Autopointer

   EXTACC = 1;  // Enable
   APTR1FZ = 1; // Don't freeze
   APTR2FZ = 1; // Don't freeze

}

//-----------------------------------------------------------------------------

unsigned char app_vendor_cmd(void)
{
  // OUT requests. Pretend we handle them all...

  if ((bRequestType & bmRT_DIR_MASK) == bmRT_DIR_OUT)
  {
    if(bRequest == RQ_GET_STATUS)
    {
      //Running = 1;
    };
    return 1;
  }

  return 1;
}

#define HISPEED	(USBCS & 0x80)

void slave_fifo_init(void) {

	EP2FIFOCFG=0;
	SYNCDELAY;
	EP4FIFOCFG=0;
	SYNCDELAY;
	EP6FIFOCFG=0;
	SYNCDELAY;
	EP8FIFOCFG=0;
	SYNCDELAY;

	EP2CFG=0;
	SYNCDELAY;
	EP4CFG=0;
	SYNCDELAY;
	EP6CFG=0;
	SYNCDELAY;
	EP8CFG=0;
	SYNCDELAY;

	// auto out/in
	REVCTL = 3;	
	SYNCDELAY;
	
	// 7: 	 1: internal clk
	// 6: 	 1: 48MHz
	// 5:	 1: clk out enable
	// 4: 	 0: no clk inversion
	// 3:    0: synchronous mode
	// 2:	 0: don't drive GSTATE
	// 0,1: 11: slave fifo
	IFCONFIG = 0xe3;
	SYNCDELAY;
	
	// ep 2 (out)

	// 7: 	 1: valid
	// 6:	 0: out
	// 5,4:	10: bulk
	// 3: 	 0: 512byte buf
	// 2:	 0: nothing!
	// 1,0: 10: doublebuf
	EP2CFG = 0xa2;
	SYNCDELAY;
	
	FIFORESET = 0x80;
	SYNCDELAY;
	
	FIFORESET = 0x82;
	SYNCDELAY;
	
	FIFORESET = 0;
	SYNCDELAY;
	
	OUTPKTEND = 0x82;
	SYNCDELAY;
	
	OUTPKTEND = 0x82;
	SYNCDELAY;

	// 7: 0: nothing
	// 6: 0: in full minus 1
	// 5: 1: out empty plus one
	// 4: 1: outout
	// 3: 0: outoin
	// 2: 0: zero len in
	// 1: 0: nothing
	// 0: 0: 8bit		
	EP2FIFOCFG = 0x30;
	SYNCDELAY;
	
	// ep 6 (in)
	
	// 7: 	 1: valid
	// 6:	 1: in
	// 5,4:	10: bulk
	// 3: 	 0: 512byte buf
	// 2:	 0: nothing!
	// 1,0: 10: doublebuf
	EP6CFG = 0xe2;
	SYNCDELAY;
	
	FIFORESET = 0x80;
	SYNCDELAY;
	
	FIFORESET = 0x86;
	SYNCDELAY;
	
	FIFORESET = 0;
	SYNCDELAY;

	// 7: 0: nothing
	// 6: 1: in full minus 1
	// 5: 0: out empty plus one
	// 4: 0: outout
	// 3: 1: outoin
	// 2: 1: zero len in
	// 1: 0: nothing
	// 0: 0: 8bit		
	EP6FIFOCFG = 0x4C;
	SYNCDELAY;
	
	EP6AUTOINLENH = HISPEED ? 2 : 0;
	SYNCDELAY;
	
	EP6AUTOINLENL = HISPEED ? 0 : 64;
	SYNCDELAY;
		
	// FLAGB = EP6FF
	// FLAGA = EP2EF
	PINFLAGSAB = 0xe8;
	SYNCDELAY;
		
	FIFOPINPOLAR = 0;
	SYNCDELAY;
}

void main(void)
{
	u8 pwr_ok=0;
	u8 usb_ok=0;
	
  EA = 0; // disable all interrupts

  /* run with 48Mhz */
  CPUCS = (CPUCS & 0x18) | 0x10;

  nexys_init();

  setup_autovectors ();
  usb_install_handlers ();

  EA = 1; // enable interrupts

  fx2_renumerate(); // simulates disconnect / reconnect
	
	//jtag_init();
	
	//usb_ep1_init();

	/* pin 7 of port d connected to mosfet gate controlling the board power
	 * ref: http://digilentinc.com/Data/Products/NEXYS/Nexys_sch.pdf
	 * same holds for Nexys2 board
	 */
	/* configure pin 7 of port d as output */
	IOD &= ~USB_ON; // initial: off
	OED |= USB_ON;
	
	// wait a bit to get the HISPEED flag right
	//while(!usb_setup_packet_avail()) {}
	
//	slave_fifo_init();
	
	
	
	/*
		TODO:
			- stall EP1 if pwr or usb down
			- init EP1 if pwr up and usb up
			
			- initialize slave fifo once pwr+usb is ready
			- disable slave fifo on power cut or usb down
	*/
	
  while(1) {

	// most important: please the host!
	if(usb_setup_packet_avail())
          usb_handle_setup_packet();  
	
	// enable USB PWR via mosfet once we're configured
	// (permission to burn 500mA yay!)
	if(usb_ok != _usb_config) {
		usb_ok = _usb_config;
		
		if(!usb_ok) {
			// this case doesn't happen as _usb_config is never reset!
			// otherwise we'd do: tristate slave fifo & pwr, mosfet power off
			//IOD |= USB_ON; // disable mosfet
		}
		else {
			IOD |= USB_ON; // enable mosfet
			if(pwr_ok) {
				usb_ep1_init(); // setup JTAG endpoint
				jtag_init(1);
			}
		}
	}
	  
	// check power switch
	if(pwr_ok != (IOA & VCC3V3_OK)) {
		
		pwr_ok = (IOA & VCC3V3_OK);
		
		if(!pwr_ok) {
			// disable/tristate slave fifo, jtag
			IFCONFIG &= ~3;
			OEA = 0;
			OEB = 0;
			jtag_init(0);
		}
		else if(usb_ok) {
			usb_ep1_init(); // setup JTAG endpoint
			jtag_init(1);
		}
	}
      
      if( (usb_ok) && (pwr_ok) )
	usb_ep1_process_request();
  }
}
