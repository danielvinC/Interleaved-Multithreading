package fgmt;
	 localparam integer WIDTH = 32;

    localparam integer THREAD_POOL_SIZE = 4 ;
    //fetch stage parameters
    localparam logic [3:0] PC_T0 = 4'b0001;
    localparam logic [3:0] PC_T1 = 4'b0010;
    localparam logic [3:0] PC_T2 = 4'b0100;
    localparam logic [3:0] PC_T3 = 4'b1000;

endpackage