module thread_selector #(parameter  THREAD_POOL_SIZE = 4)
(
    input logic clk,
    input logic rst,
    output logic [1:0] TID_fetch
);

    logic [1:0] thread_IF_internal;

    always @( posedge clk, posedge rst) begin
        if (rst) begin
            thread_IF_internal <= 2'b0;
        end else begin
            thread_IF_internal <= (thread_IF_internal < (THREAD_POOL_SIZE - 1)) ? (thread_IF_internal + 1) : 0;
        end
    end

    assign TID_fetch = thread_IF_internal;
    
endmodule