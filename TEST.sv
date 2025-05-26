`timescale 1ns/1ps

`include "heptagon.v"

`define CYCLE 50.0
`define End_CYCLE 1000000
`define PAT "coordinate.data"
`define ANS "ANS.data"

module testfixture();

integer fd;
integer fd1;
integer objnum;
integer obj_area;
integer charcount;
integer charcount1;
integer pass=0;
integer fail=0;
reg [2:0] obj_index;
reg [31:0] ans_area [0:4];
reg [2:0] ans_index [0:4];

string line;
string line1;

reg [9:0] X;
reg [9:0] Y;
reg [18:0] Area;
reg [2:0] Index;

reg clk = 0;
wire valid;
reg reset =1;

heptagon u_heptagon(
    .clk(clk),
    .reset(reset),
    .X(X),
    .Y(Y),
    .valid(valid),
    .Area(Area),
    .Index(Index)
);

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    $fsdbDumpfile("heptagon.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;
end

initial begin
    $display("---------------------");
    $display("-- Simulation Start --");
    $display("---------------------");
    #(`CYCLE*2);
    @(posedge clk); #2 reset = 1'b0;
end

reg [22:0] cycle=0;

always @(posedge clk) begin
    cycle=cycle+1;
    if (cycle > `End_CYCLE) begin
        $display("-----------------------------------------------------");
        $display("-- Failed waiting valid signal, Simulation STOP --");
        $display("-----------------------------------------------------");
        $fclose(fd);
        $finish;
    end
end

initial begin
    fd = $fopen(`PAT,"r");
    fd1 = $fopen(`ANS,"r");
    if (fd == 0 || fd1 == 0) begin
        $display ("pattern handle null");
        $finish;
    end
end

reg wait_valid;
reg get_index;
integer ap_num;
integer ob_num;
integer get_count;
integer ans_count;
reg [1:0] reset_count;

always@(posedge clk)begin
    if(get_count == 5)
        reset <= 1;
    else if(reset_count == 2)
        reset <= 0;
end

always@(posedge clk)begin
    if(get_count == 5)
        reset_count <= 1;
    else if (!reset)
        reset_count <= 0;
    else
        reset_count <= reset_count + 1;
end

always @(negedge clk ) begin
    if (reset) begin
        wait_valid=0;
        get_count=0;
    end
    else begin
        if(wait_valid == 0 & valid == 0) begin
            if(ob_num == 5 & ap_num == 7) wait_valid =1;
        end
        else begin
            if (valid ==1) begin
                wait_valid=0;

                if(Index == ans_index[get_count] && Area == ans_area[get_count]) begin
                    pass = pass +1;
                    $display("Cycle: %0d",get_count+1);
                    $display("Index: Golden/Return => %0d/%d",ans_index[get_count],Index);
                    $display("Area: Golden/Return => %0d/%d, PASS\n",ans_area[get_count],Area);
                end
                else begin
                    fail = fail +1;
                    $display("Cycle: %0d\n",get_count+1);
                    $display("Index: Golden/Return => %0d/%d",ans_index[get_count],Index);
                    $display("Area: Golden/Return => %0d/%d, FAIL\n",ans_area[get_count],Area);
                end
                get_count=get_count+1;
            end
        end
    end
end

always @(negedge clk ) begin
    if (reset) begin
        X=0;
        Y=0;
        ap_num = 0;
        ob_num = 0;
    end
    else begin
        if (!$feof(fd)) begin
            if(wait_valid ==0 & get_count == 0) begin
                charcount = $fgets (line, fd);
                if(charcount != 0) begin
                    if( line.substr(0, 5) == "object") begin
                        charcount = $sscanf(line, "object %d",objnum);
                        $display ("Object%0d:     X     Y",objnum);

                        ap_num = 1;
                        ob_num = ob_num + 1;

                        charcount = $fgets (line, fd);
                        charcount = $sscanf(line, "%d %d",X,Y);
                        $display("%d: %d, %d",ap_num, X, Y);
                    end
                    else begin
                        ap_num = ap_num+1;
                        charcount = $sscanf(line, "%d %d",X,Y);
                        $display("%d: %d, %d",ap_num, X ,Y);
                    end
                end
            end //if (!$feof(fd)) begin
        end    
        else begin
            $fclose(fd);
            $display("-----------------------------------------------------");
            if(pass == 25)
                $display("--     Simulation finish,  ALL PASS          --");
            else
                $display("-- Simulation finish,  Pass = %2d , Fail = %2d   --",pass,fail);
            $display("-----------------------------------------------------");
            $finish;
        end
    end
end

always @(negedge clk ) begin
    if (reset) begin
        ans_count = 0;
    end
    else begin
        if (!$feof(fd1)) begin
            if(ans_count < 5) begin
                charcount1 = $fgets (line1, fd1);
                if(charcount1 != 0) begin
                    if( line1.substr(0, 2) == "ANS") begin
                        charcount1 = $fgets (line1, fd1);
                        charcount1 = $sscanf(line1, "%d %d",obj_index,obj_area);
                        ans_index[ans_count] = obj_index;
                        ans_area[ans_count] = obj_area;
                        ans_count = ans_count + 1;
                    end
                    else begin
                        charcount1 = $sscanf(line1, "%d %d",obj_index,obj_area);
                        ans_index[ans_count] = obj_index;
                        ans_area[ans_count] = obj_area;
                        ans_count = ans_count + 1;
                    end
                end
            end
            else if(wait_valid ==0 &&  get_count == 5)
                ans_count = 0;
        end
    end
end

endmodule