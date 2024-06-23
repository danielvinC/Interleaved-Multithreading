import fgmt::*;

module tb_;
    logic clk;
    logic reset;
    logic [WIDTH-1:0] EXE_br_addr, PCF;
    logic EXE_BR_TAKEN;
    logic [1:0] TID_EXE;
    logic [THREAD_POOL_SIZE-1:0][WIDTH-1:0] PC_T;

    localparam CLK_PERIOD = 10;

    always #(CLK_PERIOD/2) clk = ~clk;

    IF dut(clk, reset, EXE_BR_TAKEN, EXE_br_addr, TID_EXE, PCF, PC_T);

    // initialize test
    initial
        begin
            reset <= 1; # (CLK_PERIOD*3); reset <= 0;
        end
    // generate clock to sequence tests
    always
        begin
            clk <= 1; #(CLK_PERIOD/2); clk <= 0; #(CLK_PERIOD/2);
        end

    initial begin
        EXE_BR_TAKEN <= 0;
        EXE_br_addr <= 0;
        TID_EXE <= 0;
    end

    // Check results
    always @(posedge clk) begin
        if (PC_T[2] == 12) begin
            EXE_BR_TAKEN = 1;
            EXE_br_addr = 40;
            TID_EXE = 0;
        end
    end

    always_ff @(negedge clk) begin
        if (EXE_BR_TAKEN) begin
            if (PC_T[0] === 40 && PC_T[2] === 12) begin
                $display("Simulation succeeded");
                #5;
                $stop;
            end else if (PC_T[0] !== 40 && PC_T[2] === 12) begin
                $display("Simulation failed");
                #5;
                $stop;
            end
        end
    end
endmodule

