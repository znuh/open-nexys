#-----------------------------------------------------------------------------
# Makefile for usb_jtag FX2 firmware
#-----------------------------------------------------------------------------
# Copyright 2007 Kolja Waschk, ixo.de
#-----------------------------------------------------------------------------
# This code is part of nexys. nexys is free software; you can redistribute
# it and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version. nexys is distributed in the hope
# that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.  You should have received a
# copy of the GNU General Public License along with this program in the file
# COPYING; if not, write to the Free Software Foundation, Inc., 51 Franklin
# St, Fifth Floor, Boston, MA  02110-1301  USA
#-----------------------------------------------------------------------------

LIBDIR=fx2
LIB=libfx2.lib

CC=sdcc
CFLAGS+=-mmcs51 --no-xinit-opt -I${LIBDIR}
CFLAGS+=--opt-code-size

AS=asx8051
ASFLAGS+=-plosgff

LDFLAGS=--code-loc 0x0000 --code-size 0x1800
LDFLAGS+=--xram-loc 0x1800 --xram-size 0x0800
LDFLAGS+=-Wl '-b USBDESCSEG = 0xE100'
LDFLAGS+=-L ${LIBDIR}

%.rel : %.a51
	$(AS) $(ASFLAGS) $<

%.rel : %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

default: nexys.hex

nexys.hex: vectors.rel nexys.rel dscr.rel startup.rel ${LIBDIR}/${LIB}
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $+
	packihx $@ > .tmp.hex
	rm $@
	mv .tmp.hex $@

${LIBDIR}/${LIB}:
	make -C ${LIBDIR}

dscr.rel: dscr.a51
nexys.rel: nexys.c

.PHONY: clean distclean

clean:
	make -C ${LIBDIR} clean
	rm -f *.lst *.asm *.lib *.sym *.rel *.mem *.map *.rst *.lnk *.hex *.ihx *.iic

distclean: clean

load: nexys.hex
	sudo fxload -I nexys.hex -t fx2 -v -D /proc/bus/usb/`lsusb | grep CY7C68013 | sed s/:.*// | sed s/Bus\ // | sed s/\ Device\ /\\\//`
