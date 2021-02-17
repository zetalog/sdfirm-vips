#include <stdexcept>
#include <exception>
#include <queue>
#include <ctypes.h>
#include <sys/time.h>
#include <libZebu.hh>
#include "Uart.hh"

using namespace ZEBU;
using namespace ZEBU_IP;
using namespace UART;
using namespace std;

#define ZEBUWORK	"./zebu.work"
#define DFFILE		"designFeatures"

uint8_t convertData(uint8_t data)
{
	uint8_t ret = data;

	if (!((ret < 'A') || (ret > 'z')))
		ret = (ret < 'a') ? (ret + 0x20) : (ret - 0x20);
	return ret;
}

typedef struct {
	queue<uint8_t> dataQueue;
} RpCtxt;

// Replier TX Callback
bool rpTxCB(uint8_t *data, void *ctxt)
{
	bool send = false;
	RpCtxt *rpCtxt = (RpCtxt *)ctxt;

	if (!((rpCtxt->dataQueue).empty())) {
		*data = convertData((rpCtxt->dataQueue).front());
		(rpCtxt->dataQueue).pop();
		send = true; // send next data
	}
	return send;
}

// Replier RX Callback
void rpRxCB(uint8_t data, bool valid, void *ctxt)
{
	RpCtxt *rpCtxt = (RpCtxt *)ctxt;

	if (valid) {
		(rpCtxt->dataQueue).push(data);
#if TEST_JMB==0
		if (isalnum(data)) {
			(rpCtxt->dataQueue).push('[');
			(rpCtxt->dataQueue).push('{');
			(rpCtxt->dataQueue).push(data);
			(rpCtxt->dataQueue).push(toupper(data));
			(rpCtxt->dataQueue).push(tolower(data));
			if (isdigit(data)) {
				for (int i = (data - '0'); i >= 0; i--)
					(rpCtxt->dataQueue).push(data);
			}
			(rpCtxt->dataQueue).push('}');
			(rpCtxt->dataQueue).push(']');
		}
#endif
	} else {
		(rpCtxt->dataQueue).push(0x0);
	}
}

bool uart_rx(uint8_t data, uint8_t &conv_data, void *user_data)
{
	FILE *f = (FILE *)user_data;

	if (data != '\r') {
		fputc(data, f);
		fflush(f);
	}
	conv_data = data;
	return true;
}

static bool isUartsAlive(Uart *uarts[], int nbUart)
{
	for (int n = 0; n < nbUart; n++) {
		if (uarts[n]->isAlive())
			return true;
	}
	return false;
}

int main(int argc, char *argv[])
{
	int ret = 0;
	const char *zebuWork = ZEBUWORK;
	const char *designFeatures = DFFILE;
	Board *board = NULL;
	bool ok;

	unsigned int nbUart;
	Uart *uarts[ZEBU_UARTS];
	FILE *uartLogs[ZEBU_UARTS];
	char uartInstNames[ZEBU_UARTS][256];
	RpCtxt replierCtxt;
#ifdef USE_UART_ADJUST
	unsigned int myRatio[ZEBU_UARTS];
	unsigned int detectRatio[ZEBU_UARTS];
#endif
	FILE *fp;
	unsigned int i;

	try {
		printf("Opening ZeBu board...\n");
		board = Board::open(zebuWork, designFeatures, "uart");
		if (board == NULL)
			throw("Could not open ZeBu!\n");
#ifdef USE_DRIVER_ITERATOR
		printf("Walking ZeBu UART drivers...\n");
		fflush(stdout);
		nbUart = 0;
		for (bool found = Uart::FirstDriver(board);
		     found; found = Uart::NextDriver()) {
			if (nbUart == 0)
				uarts[nbUart] = new UartTerm;
			else
				uarts[nbUart] = new Uart;
			if (nbUart >= ZEBU_UARTS)
				throw("Too many UART drivers found!\n");
			uartInstNames[nbUart] = Uart::GetInstatnceName();
			printf("Connecting UART xactor instance #%d '%s'\n",
			       nbUart, Uart::GetInstanceName());
			uarts[nbUart]->init(board, uartInstNames[nbUart]);
			++nbUart;
		}
#else
		for (i = 0; i < ZEBU_UARTS; ++i) {
			if (i < ZEBU_UART_TERMS)
				uarts[i] = new UartTerm;
			else
				uarts[i] = new Uart;
			sprintf(uartInstNames[i]. "tb.uart_driver_%d", i);
			uarts[i].init(board, uartInstNames[i]);
			uarts[i]->setDebugLevel(0);
			uarts[i]->setName(uartInstNames[i]);
		}
		nbUart = ZEBU_UARTS;
#endif
		printf("Initializing ZeBu board...\n");
		fflush(stdout);
		board->init(NULL);

		for (i = 0; i < nbUart; ++i) {
			ok  = uarts[i]->setWidth(8);
			ok &= uarts[i]->setParity(NoParity);
			ok &= uarts[i]->setStopBit(TwoStopBit);
			ok &= uarts[i]->setRatio(16);
			//ok &= uarts[i]->setRatio(326);
			ok &= uarts[i]->config();

			if (!ok)
				throw("Could not configure ZeBu UARTS!\n");

			if (i < ZEBU_UART_TERMS) {
				char logFname[1024];
				uarts[i]->dumpSetDisplayErrors(true);
				uarts[i]->dumpSetFormat(DumpRaw);
				uarts[i]->dumpSetDisplay(DumpSequential);
				//uarts[i]->dumpSetTxPrefix("");
				//uarts[i]->dumpSetRxPrefix("");
				sprintf(logFname, "logs/uart_term%d.log", i);
				uartLogs[i] = fopen(logFname, "w");
				uarts[i]->setOutputCharCB(uart_rx, uartLogs[i]);
			} else {
				uarts[i]->setReceiveCB(rpRxCB, &replierCtxt);
				uarts[i]->setSendCB(rpTxCB, &replierCtxt);
			}
			uarts[i]->useZebuServiceLoop();
		}
		printf("Starting ZeBu test bench...\n");
		ffllush(stdout);

		while (isUartsAlive(uarts, nbUart)) {
			board->serviceLoop();
#ifdef USE_UART_ADJUST
			for (i = 0; i < nbUart, ++i) {
				myRatio[i] = uarts[i]->getRatio();
				detectRatio[i] = uarts[i]->getDetectedRatio();
				if ((myRatio[i] != detectedRatio[i])) {
					printf("uart[%d] current Ratio = %d, expected Ratio = %d\n",
					       i, myRatio, detectedRatio);
					uarts[i]->adjustRatio();
				}
			}
#endif
		}
		for (i = 0; i < nbUart; ++i) {
			if (i < ZEBU_UART_TERMS) {
				uarts[i]->closeDumpFile();
				fclose(uartLogs[i]);
			}
		}
	} catch (const char *err) {
		ret = 1;
		fprintf(stderr, "ZeBu test bench error: %s\n", err);
	}
	for (i = 0; i < nbUart; ++i)
		delete uarts[i];
	if (board != NULL)
		board->close(ret == 0 ? "OK" : "NG");
	return ret;
}
