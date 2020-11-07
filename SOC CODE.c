// 0611 이민기 - TextLCD, 7-Segment IP 추가
// 0611 은찬 -  ISR tmode 변경부분 제거/ 주석부분 일부 반영(main문 딜레이 포함)
#include <stdio.h>
#include <stdlib.h>
#include "xil_exception.h"
#include "xparameters.h"
#include "xscugic.h"
#include "pushbutton.h"
#include "tftlcd_pong.h"
#include "textlcd_pong.h"
#include "sevenseg_pong.h"
#include <sleep.h>

#define INTC_DEVICE_ID      XPAR_SCUGIC_0_DEVICE_ID
#define INTC_DEVICE_INT_ID   31
#define TRUE 1

int GicConfigure(u16 DeviceId);
void ServiceRoutine(void* CallbackRef); //

XScuGic InterruptController;         // Instance of the Interrupt Controller
static XScuGic_Config* GicConfig;    // The configuration parameters of the controller

static char TFTmode = 0;
static int score = 1; //스코어모드 스코어

int main(void)
{
   int Status;
   int isWin;

   int TFTslv_reg2;
   int Temp_value;

   xil_printf("PING PONG GAME \r\n");

   Status = GicConfigure(INTC_DEVICE_ID);
   if (Status != XST_SUCCESS) {
      xil_printf("GIC Configure Failed\r\n");
      return XST_FAILURE;
   }

   TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0); // 기본 모드(2'b00)로 초기화 (혹시 몰라서 )

   while (TRUE) {
      // 주기적으로 P1 Score, P2 Score를 업데이트 (2020_06_11 할 것)
      //(최종 score 업데이트) (7-Seg에 쓰기, TFT에 쓰기) (계속 반복)
      TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8); // TFT_reg2 = {18'd0, 2 winner, 4 P2, 4 P1, 4 Final}

      //Temp_value = (score & 0x0000000f) | (TFTslv_reg2 & 0x00000ff0);
      Temp_value = (score & 0x0000000f) | (TFTslv_reg2 & 0x00003ff0);

      SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, Temp_value & 0x00000fff); // 2020_0616 민기 : 7Seg는 winner(13,14비트) 필요X
      TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, Temp_value);

      //(끝났는지판단) (slave 2 INFO : Winner, P2 Score, P1 Score, Final Score) ( 2bit, 4bit, 4bit, 4bit )
//필요X?   TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8);
      isWin = TFTslv_reg2 >> 12;
      isWin = 0x00000003 & isWin; // 하위 2비트만 보기 위한 안전장치

      if (isWin == 1) { // Player 1 win
         xil_printf(":::Main Loop ::: Player 1 win\r\n");
         // 게임승리를 축하하기 위한 로직 2020_06_11 할 것
         //////////////////////////////////////////////////////////////
         TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0); // 기본 모드(2'b00)로 초기화
         SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
         TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
//필요X?      TFTmode = 0;
      }
      else if (isWin == 2) { // Player 2 win
         xil_printf(":::Main Loop ::: Player 2 win\r\n");
         // 게임승리를 축하하기 위한 로직 2020_06_11 할 것
         //////////////////////////////////////////////////////////////
         TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0); // 기본 모드(2'b00)로 초기화
         SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
         TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
//필요X?      TFTmode = 0;
      }
      else;

   }

   return XST_SUCCESS;
}


int GicConfigure(u16 DeviceId)
{
   int Status;

   GicConfig = XScuGic_LookupConfig(DeviceId);
   if (NULL == GicConfig) {
      return XST_FAILURE;
   }

   Status = XScuGic_CfgInitialize(&InterruptController, GicConfig,
      GicConfig->CpuBaseAddress);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
      (Xil_ExceptionHandler)XScuGic_InterruptHandler,
      &InterruptController);

   Xil_ExceptionEnable();

   Status = XScuGic_Connect(&InterruptController, INTC_DEVICE_INT_ID,
      (Xil_ExceptionHandler)ServiceRoutine,
      (void*)& InterruptController);

   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   XScuGic_Enable(&InterruptController, INTC_DEVICE_INT_ID);

   return XST_SUCCESS;
}

void ServiceRoutine(void* CallbackRef)
{
   char intr;
   int TFTbutton;

   intr = PUSHBUTTON_mReadReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 0);   // 인터럽트가 어디서 왔는지 알려고 PushButton 읽기
   PUSHBUTTON_mWriteReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 0, 0);      // 0으로 Reset

   TFTmode = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0); // slv_reg0 : Mode 레지스터

   int Local_SEVENslv_reg1,Local_TFTslv_reg2;

   switch (TFTmode)
		{
			//->�⺻���� 'default' branch�� �귯��

		case 1: //mode ==READY

		   //PB1  : ��� ++ �� TFT REG�� WRITE
		   //PB2  : ��� ���Ӹ�� �� �� TFT REG�� WRITE
		   //PB3,4: NOTHING

			if ((intr & 1) == 1) { //Button 1 ����̵�
				xil_printf(":::READY MODE::: S1 Switch is pushed->NEXT MODE\r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 2); // ���� ���� �Ѿ��
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 2);
				TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 2);
			}
			else if ((intr & 2) == 2) { //Button 2 ���ӽ��۸����̵�
				xil_printf(":::READY MODE::: S2 Switch is pushed->Game MODE\r\n");   // Test Code
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 3); //���Ӹ�� ����
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 3);
				TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 3);
			}
			else if ((intr & 4) == 4) { //Button 3 nothing
				xil_printf(":::READY MODE::: S3 Switch is pushed ->Default\r\n");
			}
			else if ((intr & 8) == 8) { //Button 4 nothing
				xil_printf(":::READY MODE::: S4 Switch is pushed ->Default\r\n");
			}
			break;

		case 2: //mode ==SCORE

		   //PB 1 : TFT MODE REG �÷��� �� WRITE
		   //PB 2,3(1~4��)�� ���ھ� ���� �� SEVENSEG_S01 REG�� WRITE
		   //PB 4 : NOTHING

			if ((intr & 1) == 1) { //Button 1 ����̵�
				xil_printf(":::SCORE MODE::: S1 Switch is pushed->NEXT MODE\r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0);
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
				TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
			}
			else if ((intr & 2) == 2) { //Button 2 ���ھ�����
				if (score + 1 <= 9) score++;
				Local_SEVENslv_reg1 = SEVENSEG_PONG_mReadReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4);
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, (Local_SEVENslv_reg1 & 0xfffffff0) | score);
				Local_TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8); // slave 2 �� �ٸ� ������ ��� �ֱ� ������
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, (Local_TFTslv_reg2 & 0xfffffff0) | score);
				xil_printf(":::SCORE MODE::: S2 Switch is pushed->SCORE++: %d \r\n", score);
			}
			else if ((intr & 4) == 4) { //Button 3 ���ھ��
				if (score - 1 > 0) score--;
				Local_SEVENslv_reg1 = SEVENSEG_PONG_mReadReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4);
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, (Local_SEVENslv_reg1 & 0xfffffff0) | score);
				Local_TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8); // slave 2 �� �ٸ� ������ ��� �ֱ� ������
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, (Local_TFTslv_reg2 & 0xfffffff0) | score);
				xil_printf(":::SCORE MODE::: S3 Switch is pushed ->SCORE--: %d \r\n", score);
			}
			else if ((intr & 8) == 8) { //Button 4 nothing
				xil_printf(":::SCORE MODE::: S4 Switch is pushed ->Default\r\n");
			}
			break;

		case 3: //mode ==GAME
		   //readreg �� TFT�� ���� REG �����ٰ� ��ư �Է� ������ WRITE
		   //PB1,2: 1P UP/DOWN
		   //PB3,4: 2P UP/DOWN

			TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);

			if ((intr & 8) == 8) { //Button 4 1PUP ->2pdown
				xil_printf(":::GAME MODE::: S4 Switch is pushed-> 1P UP\r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000001);
				//sleep(1);
				/*�α�*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffe);
			}
			else if ((intr & 4) == 4) { // Button 3 1PDOWN
				xil_printf(":::GAME MODE::: S3 Switch is pushed->1P DOWN \r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000002);
				//sleep(1);
				/*�α�*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffd);
			}
			else if ((intr & 2) == 2) { //Button 2 2pUP
				xil_printf(":::GAME MODE::: S2 Switch is pushed ->2P UP\r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000004);
				sleep(1);
				/*�α�*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffb);
			}
			else if ((intr & 1) == 1) { //Button 1 -> 2pdown
				xil_printf(":::GAME MODE::: S1 Switch is pushed ->2P DOWN \r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000008);
				sleep(1);
				/*�α�*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffff7);
			}
			break;
		default: //mode==�⺻
		   //PB1    : ����̵�
		   //PB2,3,4: NOTHING
			if ((intr & 1) == 1) { //Button 1 ����̵�
				xil_printf(":::BASIC MODE::: S1 Switch is pushed->MODE CHANGE \r\n");
				TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 1); // ���� ���� �Ѿ��
				SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 1);
				TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 1);
			}
			else if ((intr & 2) == 2) { //Button 2 =nothing
				xil_printf(":::BASIC MODE::: S2 Switch is pushed(No interrupt)\r\n");
			}
			else if ((intr & 4) == 4) { //Button 3 =nothing
				xil_printf(":::BASIC MODE::: S3 Switch is pushed(No interrupt)\r\n");
			}
			else if ((intr & 8) == 8) { //Button 4 =nothing
				xil_printf(":::BASIC MODE::: S4 Switch is pushed(No interrupt)\r\n");
			}
			break;
		}
	}

