/*
 * ZETALOG's Personal COPYRIGHT
 *
 * Copyright (c) 2019
 *    ZETALOG - "Lv ZHENG".  All rights reserved.
 *    Author: Lv "Zetalog" Zheng
 *    Internet: zhenglv@hotmail.com
 *
 * This COPYRIGHT used to protect Personal Intelligence Rights.
 * Redistribution and use in source and binary forms with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    This product includes software developed by the Lv "Zetalog" ZHENG.
 * 3. Neither the name of this software nor the names of its developers may
 *    be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 4. Permission of redistribution and/or reuse of souce code partially only
 *    granted to the developer(s) in the companies ZETALOG worked.
 * 5. Any modification of this software should be published to ZETALOG unless
 *    the above copyright notice is no longer declaimed.
 *
 * THIS SOFTWARE IS PROVIDED BY THE ZETALOG AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE ZETALOG OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * @(#)jtag_dpi.c: jtag DPI-C module C-part
 * $Id: jtag_dpi.c,v 1.1 2019-05-29 13:15:00 zhenglv Exp $
 */

#include <unistd.h>
#include <svdpi.h>
#include <pthread.h>
#include <errno.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define CONFIG_JTAG_ASYNC	1
#define JTAG_SERVER_PORT	6789
#define JTAG_PACKET_SIZE	512
#ifndef INVALID_SOCKET
#define INVALID_SOCKET		-1
#endif

struct jtag_cmd {
	uint32_t cmd;
	unsigned char buffer_out[JTAG_PACKET_SIZE];
	unsigned char buffer_in[JTAG_PACKET_SIZE];
	uint32_t length;
	uint32_t nb_bits;
};
#define JTAG_COMMAND_SIZE	sizeof(struct jtag_cmd)

int jtag_server_sock = INVALID_SOCKET;
int jtag_session_sock = INVALID_SOCKET;
pthread_t jtag_thread;

static int is_le(void)
{
	return htonl(25) != 25;
}

static uint32_t from_le32(uint32_t val)
{
	return is_le() ? val : htonl(val);
}

static uint32_t to_le32(uint32_t val)
{
	return from_le32(val);
}

static void jtag_fatal(const char *string)
{
	perror(string);
	exit(1);
}

#ifdef CONFIG_JTAG_ASYNC
svBit jtag_readable = 0;
svBit jtag_writable = 0;

svBit c_jtag_readable(void)
{
	return jtag_readable;
}

svBit c_jtag_writable(void)
{
	return jtag_writable;
}

void jtag_func(void *unused)
{
}

void jtag_async_init(void)
{
	int ret;

	ret = pthread_create(&jtag_thread, NULL, jtag_func, NULL);
	if (ret)
		jtag_fatal("pthread_create");
}
#else
void jtag_async_init(void)
{
}
#endif

void c_jtag_init(void)
{
	int ret;
	int sock;
	struct sockaddr_in sa_in;
	int flags;
	unsigned short port = JTAG_SERVER_PORT;

	if (jtag_server_sock != INVALID_SOCKET)
		return;

	sock = socket(AF_INET, SOCK_STREAM, 0);
	if (sock == INVALID_SOCKET)
		jtag_fatal("socket");

	memset(&sa_in, '0', sizeof(sa_in));
	sa_in.sin_family = AF_INET;
	sa_in.sin_addr.s_addr = htonl(INADDR_ANY);
	sa_in.sin_port = htons(port);
	ret = bind(sock, (struct sockaddr *)&sa_in, sizeof (sa_in));
	if (ret)
		jtag_fatal("bind");

	ret = listen(sock, 10);
	if (ret)
		jtag_fatal("listen");

	jtag_server_sock = sock;
	printf("JTAG (DPI): opened on port %d.\n", port);

	while (jtag_server_sock != INVALID_SOCKET) {
		sock = accept(jtag_server_sock, NULL, NULL);
		if (sock == INVALID_SOCKET)
			jtag_fatal("accept");
		printf("JTAG (DPI): connected.\n")
		break;
	}
	jtag_session_sock = sock;

	flags = fcntl(jtag_server_sock, F_GETFL, 0);
	fcntl(jtag_server_sock, F_SETFL, flags | O_NONBLOCK);

	jtag_async_init();
}

void c_jtag_exit(void)
{
	if (jtag_session_sock != INVALID_SOCKET) {
		close(jtag_session_sock);
		jtag_session_sock = INVALID_SOCKET;
		printf("JTAG (DPI): disconnected.\n");
	}
	if (jtag_server_sock != INVALID_SOCKET) {
		close(jtag_server_sock);
		jtag_server_sock = INVALID_SOCKET;
		printf("JTAG (DPI): closed.\n");
	}
}

svBit c_jtag_read(int *cmd, int *length, int *nb_bits,
		  svLogicVecVal buffer[4096])
{
	ssize_t len;
	struct jtag_cmd dpi;
	int i;

	c_jtag_init();

	len = read(jtag_session_sock, &dpi, JTAG_COMMAND_SIZE);
	if (len == 0)
		jtag_fatal("close");
	if (len < 0) {
		if (errno != EAGAIN)
			jtag_fatal("read");
		return 0;
	}
	*cmd = from_le32(dpi.cmd);
	*length = from_le32(dpi.length);
	*nb_bits = from_le32(dpi.nb_bits);
#ifdef CONFIG_JTAG_DEBUG
	printf("jtag_read(%d): cmd=0x%08x, bits=%d\n",
	       *length, (uint32_t)*cmd, *nb_bits);
#endif
	/* TODO: put the content of the buffer */
	for (i = 0; i < *length; i++) {
#ifdef CONFIG_JTAG_DEBUG
		printf("jtag_read: %d=%02x\n", i, dpi.buffer_out[i]);
#endif
		buffer[i].aval = (int)(dpi.buffer_out[i]);
	}
	return 1;
}

svBit c_jtag_write(int length, const svLogicVecVal buffer[4096])
{
	ssize_t len;
	struct jtag_cmd dpi;
	int i;

	/* TODO: get the content of the buffer */
#ifdef CONFIG_JTAG_DEBUG
	printf("jtag_write(%d).\n", length);
#endif

	memset(&dpi, 0, JTAG_COMMAND_SIZE);
	dpi.cmd = to_le32(dpi.cmd);
	dpi.length = to_le32(length);
	dpi.nb_bits = to_le32(dpi.nb_bits);
	for (i = 0; i < dpi.length; i++) {
		dpi.buffer_in[i] = (uint8_t)buffer[i].aval;
#ifdef CONFIG_JTAG_DEBUG
		printf("jtag_write: %d=%02x\n", i, dpi.buffer_in[i]);
#endif
	}
	len = write(jtag_session_sock, &dpi, JTAG_COMMAND_SIZE);
	if (len < JTAG_COMMAND_SIZE)
		jtag_fatal("write");
	return 1;
}
