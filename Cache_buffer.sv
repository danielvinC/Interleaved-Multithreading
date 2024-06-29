/*
* Description: Level 1 cache 
*/
import fgmt::*;
module L1_cache #(
    parameter CTID = 0) 
    (
    // Clock and Asynchronous reset active
    input logic clk,        
    input logic reset,      
    /********************************/
    //Program Counter
    input word  PCF,   
    //
    input word block_addr_rst,
    //the index of active thread to be fetched                             
    input logic [TID_bits-1:0] TID_fetch,
    /********************************/
    //Thread ID and Instruction address for branch prefetching - interacts directly with the fifo branch target
    input word br_target, 
    input logic [TID_bits-1:0] tid_br,
    /********************************/
    //Thread ID and address of line instruction from L2 Cache
    input word PC_L2_i,
    input logic [TID_bits-1:0] tid_from_l2,
    /********************************/
    //Data response form L2 Cache
    input line l2_cache_block_rsp,
    input logic rsp_valid, 
    /********************************/
    //the branch request
    output logic br_req, 
    /********************************/
    //prefetching request
    output logic req_spec, 
    /********************************/
    //refill request
    output logic req_refill,
    /********************************/
    //hit = 1 -> found in L1 Cache, hit = 0 -> not found in L1 Cache     
    output logic hit,
    /********************************/
    // instruction output port -> to processor decode stage
    output word instr
    );
    /************************************************************************************************************************************/
    // ----------
    // Registers
    // ----------
    logic active;   //thread active
    word i_addr, instr_required; //instruction address to be fetched
    
    line cache_line;    // storage of line response from L2
    logic br_valid, cache_update_signal;

    word block_addr;
    integer block_offset;  //the offset...to extract the particular word from a block to be fetched
    block l1_block_memory;  // icache
    /********************************/
    assifn br_valid = (tid_br == CTID) ? set : (i_addr != block_addr) ? br_valid : clear; 
    assign cache_update_valid   = rsp_valid        && (tid_from_l2 == CTID);
    assign active               = TID_fetch == CTID;
    /************************************************************************************************************************************/
    /* FUNCTIONS */
    function block line_to_word(input line data);
        automatic block instr;
        for (int i = 0; i < block_size; i++) begin
            instr[i] = data[i * WIDTH +: WIDTH];
        end
        return instr;
    endfunction : line_to_word

    function integer offset_selector(input [3:0] sel);
        automatic integer instr_sl;
            case(sel)
                4'b0000: instr_sl = 0;
                4'b0100: instr_sl = 1;
                4'b1000: instr_sl = 2;
                4'b1100: instr_sl = 3;
            endcase
        return instr_sl;
    endfunction

    function word instr_selector(input integer sel, input block data);
        return data[sel];
    endfunction
    
    /************************************************************************************************************************************/
    ///////////////////// MAIN BODY ////////////////////////
    always_comb begin : cache_buffer
        /********************************/
        //instruction block update
        l1_block_memory = cache_update_valid ? line_to_word(l2_cache_block_rsp) : line_to_word(cache_line);
        /********************************/
        //if the address instruction matches the location in L1 Cache..then the address is found in L1 Cache
        hit = (i_addr[31:4] == block_addr[31:4]);
        //
        block_offset = offset_selector(i_addr[3:0]);
        //
        instr_required = instr_selector(block_offset, l1_block_memory);
        //hit = 1 -> found the required instruction -> complete
        //hit = 0 ->  not found the required instruction -> generates a bubble in the pipeline
        instr = hit ? instr_required : bubble;
        /********************************/
        //trigger refill request
        req_refill = ~hit; 
        //trigger prefetching request
        req_spec = (block_offset == 3);
        //defaults
        i_addr = 32'h0;
        br_req = clear;
        if (active) begin
            //update fetch address instruction 
            i_addr = PCF;
            br_req = clear;
        end else if (br_valid) begin
            //determine if there was a branch instruction
            i_addr = br_target;
            //trigger branch prefetching request
            br_req = (i_addr[31:4] != block_addr[31:4]);
        end
    end
    /************************************************************************************************************************************/
    always_ff @(posedge clk) begin 
        if (cache_update_valid) begin
            cache_line  <= l2_cache_block_rsp;
            block_address <= PC_L2_i;
        end else if (reset) begin
            cache_line <=  128'h0;
            block_address <= block_addr_rst;
        end 
    end
endmodule
