`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:39:35 03/04/2018 
// Design Name: 
// Module Name:    dac_ctl 
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
module dac_ctl(
    input reset_n,
    input dac_clk_in,
    input [7:0] signal_select,
	 input [7:0] clk_select,
    input ctl_data_val,
    output [13:0] dac_db
    );

reg [10:0 ] rom_addr;
wire ctl_data_val ; 
wire [13:0] dac_db , dac_db_w ;
wire [8:0] FCLK , FOUT , FCNT , Finc ;
wire[7:0]   signal_select , clk_select;
wire dac_clk_out ;
assign FCLK = (clk_select == 8'h20)? 9'd25:
					(clk_select == 8'h21)? 9'd50:
					(clk_select == 8'h22)? 9'd60:
					(clk_select == 8'h23)? 9'd100:
					(clk_select == 8'h24)? 9'd120:9'd25;
assign FOUT = {1'b0 , (signal_select - 8'h30)};
assign Finc = signal_select;


//
always @ (posedge dac_clk_in or negedge reset_n)
if(!reset_n)
	rom_addr <= 0;
else
begin
if(ctl_data_val == 1'b1)
	if(rom_addr >= 10'd600)
	rom_addr <= Finc[7:0];//保证连续
	else
	rom_addr <= rom_addr + Finc[7:0];
else
	rom_addr <= 0;	
end

wire [10:0] addra;
assign addra = (rom_addr!=0)? (rom_addr - 1'b1) : 0 ; 
//ROM
sin_rom sin_rom_mod (
  .clka(dac_clk_in), // input clka
  .addra(addra[9:0]), // input [9 : 0] addra
  .douta(dac_db_w) // output [13 : 0] douta
);

reg [13:0] dac_db_r;
always @ (posedge dac_clk_in )
begin
	dac_db_r <= dac_db_w ;
end

assign dac_db = dac_db_r;






	
/* select_io DA_IO
   (
  // From the system into the device
    .DATA_IN_FROM_PINS(dac_db_r), //Input pins
    .DATA_IN_TO_DEVICE(dac_db), //Output pins

    .CLK_IN(dac_clk_in),        // Single ended clock from IOB
    .CLK_OUT(dac_clk_out), //Fast clock ouput
    //.CLK_RESET(!reset_n), //clocking logic reset
    .IO_RESET(!reset_n)  //system reset
);*/




endmodule
