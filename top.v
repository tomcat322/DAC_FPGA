`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:03:48 03/03/2018 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module top(
    input RXD,
    output TXD,
    output DAC_SLEEP,
    output [13:0] DAC_DB,
    output DAC_CLK,
    output [14:0] RELAY,
    input CLK_25M,
	 //CDCE706 ����
	 input DAC_CLK_IN,
	 
	 output sda,
    output scl,
    output [1:0] s,
	 input RESET
    );

//wire DAC_SLEEP;
//wire DAC_CLK;
wire RXD,TXD,CLK_25M,RESET;
wire CLK25,CLK50,CLK60,CLK100,CLK120;
wire [7:0] clk_select;
wire clk_data_val;
wire sda,scl;
wire [1:0] s;
wire txd_flag , rxd_flag , txd_complete , clk_ctl_val , sin_ctl_val;
wire [7:0] rxd_data , txd_data  , sin_select;
wire dac_clk_sel ;

assign sda = 1'b1;
assign scl = 1'b1;
assign s = 2'b11;

//ʱ��ģ��
clock FPGA_PLL_mod
   (// Clock in ports
    .CLK_IN1(CLK_25M),      // IN
    // Clock out ports
    .CLK_OUT1(CLK25),     // OUT
    .CLK_OUT2(CLK50),     // OUT
    .CLK_OUT3(CLK60),     // OUT
    .CLK_OUT4(CLK100),     // OUT
    .CLK_OUT5(CLK120),     // OUT
    // Status and control signals
    .RESET(RESET));       // IN
//ʱ�ӣ�DACʹ��120Mʱ��

//����ʹ��25Mʱ��
 
//clk_mux clk_mux_mod(
//	.clk_25M(CLK25),
//	.clk25(CLK25),
//	 .clk50(CLK50),
//	 .clk60(CLK60),
//	 .clk100(CLK100),
//	 .clk120(CLK120),
//   .clk_select(clk_select),
//   .sda(sda),
//   .scl(scl),
//   .s(s),
//   .data_val(clk_data_val),
//	.rst_n(RESET),
//	.sel_clk(dac_clk_sel)
//);
//wire dac_clk_sel_G;
//BUFG dac_clk_sel_inst (
//      .O(dac_clk_sel_G), // 1-bit output: Clock buffer output
//      .I(dac_clk_sel)  // 1-bit input: Clock buffer input
//   );

////////////////////////////////////��ʱ��ѡ�񲿷ַ��ڶ��㷽�㲼��////////////////////////////////////////////////////////////////
/*
	clk_select ȡֵ
	20����ʱ��Ϊ25M		s25or50 <=1'b0 ; s25_50or100 <= 1'b0 ; s60or120 <=1'b0 ; s100or120 <=1'b0;
	21����ʱ��Ϊ50M		s25or50 <=1'b1 ; s25_50or100 <= 1'b0 ; s60or120 <=1'b0 ; s100or120 <=1'b0;
	22����ʱ��Ϊ60M		s25or50 <=1'b0 ; s25_50or100 <= 1'b0 ; s60or120 <=1'b0 ; s100or120 <=1'b1;
	23����ʱ��Ϊ100M		s25or50 <=1'b0 ; s25_50or100 <= 1'b1 ; s60or120 <=1'b0 ; s100or120 <=1'b0;
	24����ʱ��Ϊ120M		s25or50 <=1'b0 ; s25_50or100 <= 1'b0 ; s60or120 <=1'b1 ; s100or120 <=1'b1;
*/
wire clk25or50, clk25_50or100, clk60or120;

wire s25or50,s25_50or100,s60or120,s100or120;

wire [3:0] clk_sel_wire;

assign clk_sel_wire = (clk_select == 8'h20) ? 4'b0000:
							(clk_select ==8'h21)? 4'b1000:
							(clk_select ==8'h22)? 4'b0001:
							(clk_select ==8'h23)? 4'b0100:
							(clk_select ==8'h24)? 4'b0011:4'b0000;

assign s100or120		 	= clk_sel_wire[0];
assign s60or120			= clk_sel_wire[1];
assign s25_50or100 		= clk_sel_wire[2];
assign s25or50 			= clk_sel_wire[3];
BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   s25or50_inst (
      .O(clk25or50),   // 1-bit output: Clock buffer output
      .I0(CLK25), // 1-bit input: Clock buffer input (S=0)
      .I1(CLK50), // 1-bit input: Clock buffer input (S=1)
      .S(s25or50)    // 1-bit input: Clock buffer select
   );

BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   s60or120_inst (
      .O(clk60or120),   // 1-bit output: Clock buffer output
      .I0(CLK60), // 1-bit input: Clock buffer input (S=0)
      .I1(CLK120), // 1-bit input: Clock buffer input (S=1)
      .S(s60or120)    // 1-bit input: Clock buffer select
   );

wire [14:0] DAC_DB_port25or50 , DAC_DB_port60or120 , DAC_DB_port100;

//ROM 25or50
dac_ctl dac_ctl_mod25or50(
     .reset_n(RESET),
     .dac_clk_in(clk25or50),  // ʵ��ʹ��Ϊ DAC_CLK_IN    ������CLK25
     .signal_select(sin_select),
	  .clk_select	(clk_select),
     .ctl_data_val	(clk_ctl_val && sin_ctl_val),
     .dac_db			(DAC_DB_port25or50),
    );
//ROM 60or120
dac_ctl dac_ctl_mod25or50(

     .reset_n(RESET),
     .dac_clk_in(s60or120),  // ʵ��ʹ��Ϊ DAC_CLK_IN    ������CLK25
     .signal_select(sin_select),
	  .clk_select	(clk_select),
     .ctl_data_val	(clk_ctl_val && sin_ctl_val),
     .dac_db			(DAC_DB_port60or120),
    );
/////////////////////////////////////////////////////////////////////////////////////////////////
//DAC ���ģ��
dac_ctl dac_ctl_mod(

     .reset_n(RESET),
     .dac_clk_in(CLK100),  // ʵ��ʹ��Ϊ DAC_CLK_IN    ������CLK25
     .signal_select(sin_select),
	  .clk_select	(clk_select),
     .ctl_data_val	(clk_ctl_val && sin_ctl_val),
     .dac_db			(DAC_DB_port100),
    );

assign DAC_DB = (clk_select == 8'h20 or clk_select ==8'h21) ?DAC_DB_port25or50:
				(clk_select == 8'h22 or clk_select ==8'h24) ?DAC_DB_port60or120:
				(clk_select ==8'h23)? DAC_DB_port100 : DAC_DB_port25or50 ;

assign dac_clk_sel = (clk_select == 8'h20 or clk_select ==8'h21) ? clk25or50:
				(clk_select == 8'h22 or clk_select ==8'h24) ?s60or120:
				(clk_select ==8'h23)? CLK100 : clk25or50 ;

ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
   ) dac_out_clk_inst (
      .Q(DAC_CLK),   // 1-bit DDR output data
      .C0(dac_clk_sel),   // 1-bit clock input
      .C1(~dac_clk_sel),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D0(1'b0), // 1-bit data input (associated with C0)
      .D1(1'b11), // 1-bit data input (associated with C1)
      .R(1'b0),   // 1-bit reset input
      .S(1'b0)    // 1-bit set input
   );
//ϵͳ����ģ��

sys_ctl sys_ctl_mod(
    .clk_25M		(CLK25),
    .reset_n		(RESET),
    .rxd_flag		(rxd_flag),	// ���ڽ������ݱ�־���ø�һ������
    .rxd_data		(rxd_data), //���ڽ������ݶ˿�
    .txd_flag		(txd_flag),//�����ݷ���ʱ�ø�һ������
	 .txd_complete (txd_complete), //���ڷ���һ���ֽ����
    .txd_data		(txd_data),//��������
    .clk_select	(clk_select),//���ʱ��ѡ��
    .sin_select	(sin_select),//����ź�Ƶ��ѡ��
    .clk_ctl_val	(clk_ctl_val),//������ݿ�����Ч
    .sin_ctl_val	(sin_ctl_val),//������ݿ�����Ч
    .RELAY			(RELAY),//�̵������ƶ˿�
    .DAC_SLEEP		(DAC_SLEEP)	//DAC ���߶˿� �ߵ�ƽ��Ч
    );
//422���� ģ��
wire txd_bps_start,txd_bps_clk;
uart_clk TXD_uart_clk_mod(
     .clk(CLK25),
     .rst_n(RESET),
     .bps_start(txd_bps_start),
     .bps_clk(txd_bps_clk)
    );
uart_txd uart_txd_mod(
	.clk			(CLK25),
	.clk_bps		(txd_bps_clk),
	.rst_n		(RESET),
	.bps_start	(txd_bps_start),
	.txd_start	(txd_flag),
	.txd_data	(txd_data),
	.txd_flag	(txd_complete),
	.txd			(TXD)
//	txd_fifo_rdreq
);

//422����ģ��
wire rxd_clk_bps , rxd_bps_start;
uart_rxd uart_rxd_mod(
	.clk			(CLK25),
	.rst_n		(RESET),
	.clk_bps		(rxd_clk_bps),
	.bps_start	(rxd_bps_start),
	.rxd			(RXD),
	.rxd_flag	(rxd_flag),
	.rxd_data	(rxd_data)
);
uart_clk RXD_uart_clk_mod(
     .clk(CLK25),
     .rst_n(RESET),
     .bps_start(rxd_bps_start),
     .bps_clk(rxd_clk_bps)
    );

endmodule
