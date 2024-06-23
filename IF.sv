import fgmt::*;

module IF
	(
    input logic clk, rst,
    input logic EXE_BR_TAKEN,
    input logic [WIDTH-1:0] EXE_br_addr,
    input logic [1:0] TID_EXE,
    output logic [WIDTH-1:0] PCF,
	 output logic [THREAD_POOL_SIZE-1:0] [WIDTH-1:0] PC_T
    // output logic [(WIDTH-1):0] IF_word
    );

    logic [1:0] TID_fetch;
    logic [THREAD_POOL_SIZE-1:0] [WIDTH-1:0] IF_t;

    PC_updater #(4) PC_updater(clk, rst, EXE_BR_TAKEN, EXE_br_addr, TID_EXE, TID_fetch, PCF, PC_T);
    thread_selector #(4) TSL(clk, rst, TID_fetch);
    mux4 #(32) PCselect(PC_T[0], PC_T[1], PC_T[2], PC_T[3], TID_fetch, PCF);
    // Cache_line_buffer #(32) CT0(PCF, IF_t[0]);
    // Cache_line_buffer #(32) CT1(PCF, IF_t[1]);
    // Cache_line_buffer #(32) CT2(PCF, IF_t[2]);
    // Cache_line_buffer #(32) CT3(PCF, IF_t[3]);
    // mux4 #(32) IF_select(IF_t[0], IF_t[1], IF_t[2], IF_t[3], TID_fetch, IF_word);
endmodule

 module mux4 #(parameter WIDTH = 8)
     (input logic [WIDTH-1:0] d0, d1, d2, d3, 
     input logic [1:0] s,
     output logic [WIDTH-1:0] y);
     assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);
 endmodule

//module mux4 #(parameter WIDTH = 8)
//    (input logic [WIDTH-1:0] d0, d1, d2, d3,
//     input logic [1:0] s,
//     output logic [WIDTH-1:0] y);
//
//    always_comb begin
//        case (s)
//            2'b00: y = d0;
//            2'b01: y = d1;
//            2'b10: y = d2;
//            2'b11: y = d3;
//            default: y = {WIDTH{1'b0}}; // Default case (optional)
//        endcase
//    end
//endmodule
