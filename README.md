
                              SDFIRM VIPs

This repository dipicts sdfirm IC verification methodology.

The sdfirm can be used as an SoC verification environment, however most of
the caseis, the environment need to interactive with an console driven by
sdfirm, and sometimes developers need a debuggng facility to address sdfirm
issues. The VCS bench may connect to sdfirm provided verification IPs to
achieve various verification purpose:

1. CPU verification
   In this environment, CPUs connects to cluster bus (e.x., ACE), and the
   only IRQ source is the timer. Then you should use CONFIG_SYS_RT in
   sdfirm and connects uart_pl01x_dpi.v on the test bench.
2. IP verification
   In this environment, bus IO IPs need to be provided to implement sdfirm
   IO APIs (__raw_readx()/__raw_writex()), sdfirm can simply use host
   standard input/output. IRQs cannot be tested, thus you should use
   CONFIG_SYS_NOIRQ in sdfirm.
3. SoC verification
   In this environment, sdfirm runs on a target CPU model and SoC may
   provide UART IRQs. Then you should use CONFIG_SYS_IRQ in sdfirm and
   connects uart_vip.v on the test bench if you have a real UART model
   or uart_16550_dpi.v if you don't have a real UART model.

sdfirm also provides jtag_dpi.v module for being used with openocd
jtag_vpi adapter to provide single step debugging capability.
