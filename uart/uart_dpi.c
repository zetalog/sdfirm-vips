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
 * @(#)uart_dpi.c: uart DPI-C module C-part
 * $Id: uart_dpi.c,v 1.1 2019-05-29 12:41:00 zhenglv Exp $
 */

#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <fcntl.h>
#include <svdpi.h>
#include <sys/select.h>
#include <pthread.h>
#include <termios.h>

#define max(a, b)		((a) > (b) ? (a) : (b))
#define CONSOLE_TIMEOUT_US	(100 * 1000) /* 100ms */

svBit console_readable = 0;
svBit console_writable = 0;
int console_stopped = 0;
pthread_t console_thread;
FILE *console_log = NULL;
struct termios term_orig_flags;

void console_func(void *unused)
{
	fd_set rfds, wfds;
	int wfd = fileno(stdin);
	int rfd = fileno(stdout);
	int maxfds, ret;
	struct timeval tv;

	ret = pthread_detach(pthread_self());
	if (ret) {
		perror("pthread_detach");
		return;
	}

	printf("Enter pseudo console...\n");

	maxfds = max(wfd, rfd) + 1;
	while (!console_stopped) {
		if (console_readable && console_writable) {
			usleep(CONSOLE_TIMEOUT_US);
			continue;
		}
		tv.tv_sec = 0;
		tv.tv_usec = CONSOLE_TIMEOUT_US;
		FD_ZERO(&rfds);
		FD_ZERO(&wfds);
		if (!console_readable)
			FD_SET(rfd, &rfds);
		if (!console_writable)
			FD_SET(wfd, &wfds);
		ret = select(maxfds, &rfds, &wfds, NULL, &tv);
		if (ret < 0) {
			perror("select");
			break;
		}
		if (ret == 0)
			continue;
		if (FD_ISSET(rfd, &rfds) && !console_readable) {
#ifdef CONFIG_UART_DEBUG_POLL
			printf("Readable.\n");
#endif
			console_readable = 1;
		}
		if (FD_ISSET(wfd, &wfds) && !console_writable) {
#ifdef CONFIG_UART_DEBUG_POLL
			printf("Writable.\n");
#endif
			console_writable = 1;
		}
	}

	if (console_log) {
		fclose(console_log);
		console_log = NULL;
	}

	printf("Exit pseudo console...\n");
}

void c_con_exit(void)
{
	if (!console_stopped) {
		console_stopped = 1;
		tcsetattr(fileno(stdin), TCSANOW, &term_orig_flags);
	}
}

void c_con_init(void)
{
	int ret;
	struct termios newflags;

	setvbuf(stdin, NULL, _IONBF, 0);
	setvbuf(stdout, NULL, _IONBF, 0);

#ifdef CONFIG_UART_LOG
	console_log = fopen("uart.log", "w");
	if (!console_log)
		perror("fopen");
#endif

	tcgetattr(fileno(stdin), &term_orig_flags);
	newflags = term_orig_flags;
	newflags.c_lflag &= ~(ICANON | ECHO);
	tcsetattr(fileno(stdin), TCSANOW, &newflags);

	ret = pthread_create(&console_thread, NULL, console_func, NULL);
	if (ret)
		perror("pthread_create");

	atexit(c_con_exit);
}

svBit c_con_readable(void)
{
#ifdef CONFIG_UART_DEBUG_POLL
	printf("Readable=%s\n", console_readable ? "yes" : "no");
#endif
	return console_readable;
}

svBit c_con_writable(void)
{
#ifdef CONFIG_UART_DEBUG_POLL
	printf("Writable=%s\n", console_writable ? "yes" : "no");
#endif
	return console_writable;
}

void c_con_write(char data)
{
	console_writable = 0;
	putchar(data);
	if (console_log)
		fprintf(console_log, "%c", data);
}

char c_con_read(void)
{
	console_readable = 0;
	return getchar();
}
