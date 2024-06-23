import fgmt::*;

module PC_updater # (parameter THREAD_POOL_SIZE = 4)
    (input logic clk, reset,
    input logic EXE_BR_TAKEN,
    input logic [31:0] EXE_br_addr,
    input logic [1:0] TID_EXE,
    input logic [1:0] TID_fetch,
    input logic [WIDTH-1:0] PCF,
    output logic [(THREAD_POOL_SIZE-1):0] [WIDTH-1:0] PC_T);

    logic [(THREAD_POOL_SIZE-1):0] en, thread_sl, thread_active;
    logic [(THREAD_POOL_SIZE-1):0] [WIDTH-1:0] PCNext, PCPlus4;
    logic [WIDTH-1:0] PC_br, PCPlus4_F;


    assign thread_active = TID_fetch[1] ? (TID_fetch[0] ? PC_T3 : PC_T2) : (TID_fetch[0] ? PC_T1 : PC_T0);
    
    EXE_BTB #(WIDTH) btb(clk, reset, EXE_BR_TAKEN, EXE_br_addr, TID_EXE, PC_br, thread_sl);
    adder pcadd(PCF, 32'h4, PCPlus4_F);
    demux1x4 #(WIDTH) demux(PCPlus4_F, TID_fetch, PCPlus4);
    
    //this part of logic and registers is replicated as many times as the supported threads:
    genvar i;
    generate
        for (i = 0; i< THREAD_POOL_SIZE ; i++) begin: pc_update_logic 
            mux2 #(WIDTH) mux2(PCPlus4[i], PC_br, thread_sl[i], PCNext[i]);
            PC_thread #(WIDTH) PCT(clk, reset, en[i], PCNext[i], PC_T[i]);
            assign en[i] = thread_sl[i] || thread_active[i];
        end
    endgenerate
endmodule

module PC_thread #(parameter WIDTH = 8)
(
    input logic clk,                    // Clock input
    input logic rst,                    // Active-high reset
    input logic Active_thread,          // Active thread indicator
    input logic [WIDTH-1:0] PCNext,     // Data input
    output logic [WIDTH-1:0] PC_fetch   // Data output
);

    logic [WIDTH-1:0] PC_n, PC_q;             // Internal storage for the value

    // Output the stored value on the positive edge of the clock
    always_ff @(posedge clk, posedge rst) begin
        if (rst) PC_q <= {WIDTH{1'b0}}; // Reset the stored value to 0 on reset
        else PC_q <= PC_n;              // Output the stored value on posedge clk
    end
    // Level-sensitive update to PC_value when Active_thread is high
    assign 	PC_n = (Active_thread) ? PCNext : PC_q;
	assign 	PC_fetch = PC_q;

endmodule

module EXE_BTB #(parameter WIDTH = 8)
    (input logic clk, reset,
     input logic EXE_BR_TAKEN,
     input logic [WIDTH-1:0] EXE_br_addr,
     input logic [1:0] TID_EXE,
     output logic [WIDTH-1:0] PC_br,
     output logic [THREAD_POOL_SIZE-1:0] thread_sl);

    logic [WIDTH-1:0] PC_BR_taken_n, PC_BR_taken_q;
    logic [THREAD_POOL_SIZE-1:0] THEAD_BR_SL_n, THEAD_BR_SL_q;

    always @* begin
        // Initialize intermediate signals
        PC_BR_taken_n = 32'b0;
        THEAD_BR_SL_n = 4'b0;

        if (EXE_BR_TAKEN) begin
            PC_BR_taken_n = EXE_br_addr;
            THEAD_BR_SL_n = TID_EXE[1] ? (TID_EXE[0] ? PC_T3 : PC_T2) : (TID_EXE[0] ? PC_T1 : PC_T0);
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            PC_BR_taken_q <= 32'b0;
            THEAD_BR_SL_q <= 4'b0;
        end else begin
            PC_BR_taken_q <= PC_BR_taken_n;
            THEAD_BR_SL_q <= THEAD_BR_SL_n;
        end
    end
endmodule

module demux1x4 #(parameter WIDTH = 8) 
    (input logic [WIDTH-1:0] in, // input
    input logic [1:0] sel, // 2-bit select input
    output logic [3:0] [WIDTH-1:0] out); // 3 outputs for the three data lines
    always_comb begin
        // Initialize all outputs to 0
        // Initialize all outputs to 0
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        // Route the input to the selected output
        case(sel)
            2'b00: out[0] = in;
            2'b01: out[1] = in;
            2'b10: out[2] = in;
            2'b11: out[3] = in;
        endcase
    end
endmodule

module mux2 #(parameter WIDTH = 8)
    (input logic [WIDTH-1:0] d0, d1,
    input  logic             s,
    output logic [WIDTH-1:0] y);
    assign y = s ? d1 : d0;
endmodule

module adder(input [31:0] a, b,
        output [31:0] y);
        assign y = a + b;
endmodule


