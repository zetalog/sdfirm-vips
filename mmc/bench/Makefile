srcdir=..
benchdir=$(srcdir)/bench

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
QUIET=
else
Q ?=@
QUIET=-quiet
endif

mdir=$(srcdir)/master
sdir=$(srcdir)/slave

MSRC=\
	$(mdir)/SD_controller_top_tb.v \
	$(mdir)/SD_controller_top.v \
	$(mdir)/SD_Bd.v \
	$(mdir)/SD_FIFO_RX_Filler.v \
	$(mdir)/SD_FIFO_TX_Filler.v \
	$(mdir)/SD_clock_divider.v \
	$(mdir)/SD_cmd_master.v \
	$(mdir)/SD_cmd_serial_host.v \
	$(mdir)/SD_defines.v \
	$(mdir)/SD_crc_16.v \
	$(mdir)/SD_crc_7.v \
	$(mdir)/SD_data_host.v \
	$(mdir)/SD_data_master.v \
	$(mdir)/smii_rx_fifo.v \
	$(mdir)/smii_rx_fifo_tb.v \
	$(mdir)/smii_tx_fifo.v \
	$(mdir)/smii_tx_fifo_tb.v

VERILOG_SRC = $(MSRC)

all: build

build:
	@echo '##### Building ######'
	$(Q)iverilog -I$(mdir) -osd_tb.vvp $(VERILOG_SRC)

sim: build
	@echo '##### Start the simulation ######'
	$(Q)vvp -n -M. -msd sd_tb.vvp &
	@sleep 1
clean:
	@rm -rf *.o *~ *.vpi *.vvp *.vcd test_client
