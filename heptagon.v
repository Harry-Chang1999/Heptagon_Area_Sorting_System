`timescale 1ns/1ps

module heptagon(
    input        clk,      // Clock signal
    input        reset,    // Asynchronous active-high reset
    input  [9:0] X,        // X-coordinate input (unsigned)
    input  [9:0] Y,        // Y-coordinate input (unsigned)
    output       valid,    // Output valid signal
    output [2:0] Index,    // Sorted heptagon index output
    output [18:0] Area     // Sorted heptagon area output
);

    reg valid;
    reg [2:0] Index;
    reg [18:0] Area;

    reg [9:0] heptx[0:34];         //Heptagon x
    reg [9:0] hepty[0:34];         //Heptagon y
    reg signed [10:0] refx_0[0:4]; //Starting point x
    reg signed [10:0] refx_1[0:4]; //Ref point x
    reg signed [10:0] refy_0[0:4]; //Starting point y
    reg signed [10:0] refy_1[0:4]; //Ref point y
    reg signed [20:0] cp[0:4];     //Cross product result
    reg signed [20:0] area[0:4];   //The area after sorting
    reg exchange[0:4];             //If swapping during sorting exchange=1, otherwise 0
    reg [2:0] ref_index[0:4];      //Ref point index
    reg [2:0] cmp_index;           //Comparison point index
    reg [4:0] state,next_state;    //Finite state machine
    parameter data='d0,init='d1,cal_cp='d2,cc_sort='d3,cal_ref='d4,cal_area='d5,bub_init='d6,bub_cal='d7,out='d8,finish='d9; //All state

    reg [5:0] counter;     //Determines whether to enter the 'init' state and serves as the index for the coordinate storage register
    reg [2:0] ref_num;     //Ref point index
    reg [2:0] bub_count;   //Compared point of bubble sort
    reg [2:0] bub_idx;     //Starting point of bubble sort
    reg [2:0] findex[0:4]; //Area index after Bubble Sort
    reg [2:0] show_time;   //Counter for result printing

    reg signed [20:0] quadx[0:9]; //With the starting point as(0,0),calculate the quadrant of Ref point and the comparison point
    reg signed [20:0] quady[0:9];

    integer i,j,k;

    //state, next_state
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            state<=data;
        end
        else begin
            state<=next_state;
        end
    end

    always @(*)begin
        case(state)
            data:next_state=(counter==6'd34)?init:data;
            init:next_state=cal_cp;
            cal_cp:next_state=cc_sort;
            cc_sort:next_state=(cmp_index==3'd6)?cal_ref:cal_cp;
            cal_area:next_state=(ref_num==3'd5 && exchange[0]==1'b0&&exchange[1]==1'b0&&exchange[2]==1'b0&&exchange[3]==1'b0&&exchange[4]==1'b0)?cal_area:init;
            cal_area:next_state=bub_init;
            bub_init:next_state=bub_cal;
            bub_cal:next_state=(bub_idx==3'd4)?out:bub_cal;
            out:next_state=(show_time==3'd5)?finish:out;
            finish:next_state=finish;
        endcase
    end

    //valid
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            valid<=1'b0;
        end
        else begin
            if(state==out) valid<=1'b1;
        end
    end

    //Area
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            Area<=19'd0;
        end
        else begin
            if(state==out) Area<=area[show_time];
        end
    end

    //Index
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            Index<=3'd0;
        end
        else begin
            if(state==out) Index<=findex[show_time];
        end
    end

    //bub_idx
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            bub_idx<=3'd0;
        end
        else begin
            if(state==bub_cal)begin
                if(bub_count==3'd4) bub_idx<=bub_idx+3'd1;
            end
        end
    end

    //bub_count
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            bub_count<=3'd1;
        end
        else begin
            if(state==bub_cal)begin
                if(bub_count==3'd4) bub_count<=bub_idx+3'd2;
                else bub_count<=bub_count+3'd1;
            end
        end
    end

    //ref_num
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            ref_num<=3'd1;
        end
        else begin
            if(state==cal_ref)begin
                if(exchange[0]==1'b0&&exchange[1]==1'b0&&exchange[2]==1'b0&&exchange[3]==1'b0&&exchange[4]==1'b0) ref_num<=ref_num+3'd1;
            end
        end
    end

    //counter
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            counter<=6'd0;
        end
        else begin
            if(counter==6'd34) counter<=6'd0;
            else counter<=counter+6'd1;
        end
    end

    //heptx
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(i=0;i<36;i=i+1) heptx[i]<=10'd0;
        end
        else begin
            if(state==data) heptx[counter]<=X;
            else if(state==cc_sort)begin
                if(cp[0][20]==1'b1)begin
                    if(quadx[0]<0 && quadx[5]>0 && quady[0]>0 && quady[5]<0);
                    else begin
                        heptx[ref_index[0]]<=heptx[cmp_index];
                        heptx[cmp_index]<=heptx[ref_index[0]];
                    end
                end
                if(cp[1][20]==1'b1)begin
                    if(quadx[1]<0 && quadx[6]>0 && quady[1]>0 && quady[6]<0);
                    else begin
                        heptx[ref_index[1]+10'd7]<=heptx[cmp_index+10'd7];
                        heptx[cmp_index+10'd7]<=heptx[ref_index[1]+10'd7];
                    end
                end
                if(cp[2][20]==1'b1)begin
                    if(quadx[2]<0 && quadx[7]>0 && quady[2]>0 && quady[7]<0);
                    else begin
                        heptx[ref_index[2]+10'd14]<=heptx[cmp_index+10'd14];
                        heptx[cmp_index+10'd14]<=heptx[ref_index[2]+10'd14];
                    end
                end
                if(cp[3][20]==1'b1)begin
                    if(quadx[3]<0 && quadx[8]>0 && quady[3]>0 && quady[8]<0);
                    else begin
                        heptx[ref_index[3]+10'd21]<=heptx[cmp_index+10'd21];
                        heptx[cmp_index+10'd21]<=heptx[ref_index[3]+10'd21];
                    end
                end
                if(cp[4][20]==1'b1)begin
                    if(quadx[4]<0 && quadx[9]>0 && quady[4]>0 && quady[9]<0);
                    else begin
                        heptx[ref_index[4]+10'd28]<=heptx[cmp_index+10'd28];
                        heptx[cmp_index+10'd28]<=heptx[ref_index[4]+10'd28];
                    end
                end
            end
        end
    end

    //hepty
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(i=0;i<36;i=i+1) hepty[i]<=10'd0;
        end
        else begin
            if(state==data) hepty[counter]<=Y;
            else if(state==cc_sort)begin
                if(cp[0][20]==1'b1)begin
                    if(quadx[0]<0 && quadx[5]>0 && quady[0]>0 && quady[5]<0);
                    else begin
                        hepty[ref_index[0]]<=hepty[cmp_index];
                        hepty[cmp_index]<=hepty[ref_index[0]];
                    end
                end
                if(cp[1][20]==1'b1)begin
                    if(quadx[1]<0 && quadx[6]>0 && quady[1]>0 && quady[6]<0);
                    else begin
                        hepty[ref_index[1]+10'd7]<=hepty[cmp_index+10'd7];
                        hepty[cmp_index+10'd7]<=hepty[ref_index[1]+10'd7];
                    end
                end
                if(cp[2][20]==1'b1)begin
                    if(quadx[2]<0 && quadx[7]>0 && quady[2]>0 && quady[7]<0);
                    else begin
                        hepty[ref_index[2]+10'd14]<=hepty[cmp_index+10'd14];
                        hepty[cmp_index+10'd14]<=hepty[ref_index[2]+10'd14];
                    end
                end
                if(cp[3][20]==1'b1)begin
                    if(quadx[3]<0 && quadx[8]>0 && quady[3]>0 && quady[8]<0);
                    else begin
                        hepty[ref_index[3]+10'd21]<=hepty[cmp_index+10'd21];
                        hepty[cmp_index+10'd21]<=hepty[ref_index[3]+10'd21];
                    end
                end
                if(cp[4][20]==1'b1)begin
                    if(quadx[4]<0 && quadx[9]>0 && quady[4]>0 && quady[9]<0);
                    else begin
                        hepty[ref_index[4]+10'd28]<=hepty[cmp_index+10'd28];
                        hepty[cmp_index+10'd28]<=hepty[ref_index[4]+10'd28];
                    end
                end
            end
        end
    end

    //cmp_index
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            cmp_index[j]<=3'd0;
        end
        else begin
            if(state==init) cmp_index<=ref_num+3'd1;
            else if(state==cc_sort) cmp_index<=cmp_index+3'd1;
        end
    end

    //ref_index
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) ref_index[j]<=3'd0;
        end
        else begin
            if(state==init) begin
                for(j=0;j<5;j=j+1) ref_index[j]<=ref_num;
            end
            else if(state==cc_sort)begin
                if(cp[0][20]==1'b1)begin
                    if(quadx[0]<0 && quadx[5]>0 && quady[0]>0 && quady[5]<0);
                    else begin
                        ref_index[0]<=cmp_index;
                    end
                end
                if(cp[1][20]==1'b1)begin
                    if(quadx[1]<0 && quadx[6]>0 && quady[1]>0 && quady[6]<0);
                    else begin
                        ref_index[1]<=cmp_index;
                    end
                end
                if(cp[2][20]==1'b1)begin
                    if(quadx[2]<0 && quadx[7]>0 && quady[2]>0 && quady[7]<0);
                    else begin
                        ref_index[2]<=cmp_index;
                    end
                end
                if(cp[3][20]==1'b1)begin
                    if(quadx[3]<0 && quadx[8]>0 && quady[3]>0 && quady[8]<0);
                    else begin
                        ref_index[3]<=cmp_index;
                    end
                end
                if(cp[4][20]==1'b1)begin
                    if(quadx[4]<0 && quadx[9]>0 && quady[4]>0 && quady[9]<0);
                    else begin
                        ref_index[4]<=cmp_index;
                    end
                end
            end
        end
    end

    //exchange
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) exchange[j]<=1'b0;
        end
        else begin
            if(state==init)begin
                for(j=0;j<5;j=j+1) exchange[j]<=1'b0;
            end
            else if(state==cc_sort)begin
                if(cp[0][20]==1'b1)begin
                    if(quadx[0]<0 && quadx[5]>0 && quady[0]>0 && quady[5]<0);
                    else begin
                        exchange[0]<=1'b1;
                    end
                end
                if(cp[1][20]==1'b1)begin
                    if(quadx[1]<0 && quadx[6]>0 && quady[1]>0 && quady[6]<0);
                    else begin
                        exchange[1]<=1'b1;
                    end
                end
                if(cp[2][20]==1'b1)begin
                    if(quadx[2]<0 && quadx[7]>0 && quady[2]>0 && quady[7]<0);
                    else begin
                        exchange[2]<=1'b1;
                    end
                end
                if(cp[3][20]==1'b1)begin
                    if(quadx[3]<0 && quadx[8]>0 && quady[3]>0 && quady[8]<0);
                    else begin
                        exchange[3]<=1'b1;
                    end
                end
                if(cp[4][20]==1'b1)begin
                    if(quadx[4]<0 && quadx[9]>0 && quady[4]>0 && quady[9]<0);
                    else begin
                        exchange[4]<=1'b1;
                    end
                end
            end
        end
    end

    //refx_0
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) refx_0[j]<=11'd0;
        end
        else begin
            if(state==init)begin
                refx_0[0]<=heptx[0];
                refx_0[1]<=heptx[7];
                refx_0[2]<=heptx[14];
                refx_0[3]<=heptx[21];
                refx_0[4]<=heptx[28];
            end
        end
    end

    //refx_1
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) refx_1[j]<=11'd0;
        end
        else begin
            if(state==init)begin
                refx_1[0]<=$signed({1'b0,heptx[ref_num]});
                refx_1[1]<=$signed({1'b0,heptx[ref_num+10'd7]});
                refx_1[2]<=$signed({1'b0,heptx[ref_num+10'd14]});
                refx_1[3]<=$signed({1'b0,heptx[ref_num+10'd21]});
                refx_1[4]<=$signed({1'b0,heptx[ref_num+10'd28]});
            end
        end
    end

    //refy_0
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) refy_0[j]<=11'd0;
        end
        else begin
            if(state==init)begin
                refy_0[0]<=hepty[0];
                refy_0[1]<=hepty[7];
                refy_0[2]<=hepty[14];
                refy_0[3]<=hepty[21];
                refy_0[4]<=hepty[28];
            end
        end
    end

    //refy_1
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) refy_1[j]<=11'd0;
        end
        else begin
            if(state==init)begin
                refy_1[0]<=$signed({1'b0,hepty[ref_num]});
                refy_1[1]<=$signed({1'b0,hepty[ref_num+10'd7]});
                refy_1[2]<=$signed({1'b0,hepty[ref_num+10'd14]});
                refy_1[3]<=$signed({1'b0,hepty[ref_num+10'd21]});
                refy_1[4]<=$signed({1'b0,hepty[ref_num+10'd28]});
            end
        end
    end

    //cp
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) cp[j]<=21'd0;
        end
        else begin
            if(state==cal_cp)begin
                cp[0]<=$signed(refx_1[0]-refx_0[0])*$signed(({1'b0,hepty[cmp_index]})-refy_0[0])-$signed(({1'b0,heptx[cmp_index]})-refx_0[0])*$signed(refy_1[0]-refy_0[0]);
                cp[1]<=$signed(refx_1[1]-refx_0[1])*$signed(({1'b0,hepty[cmp_index+10'd7]})-refy_0[1])-$signed(({1'b0,heptx[cmp_index+10'd7]})-refx_0[1])*$signed(refy_1[1]-refy_0[1]);
                cp[2]<=$signed(refx_1[2]-refx_0[2])*$signed(({1'b0,hepty[cmp_index+10'd14]})-refy_0[2])-$signed(({1'b0,heptx[cmp_index+10'd14]})-refx_0[2])*$signed(refy_1[2]-refy_0[2]);
                cp[3]<=$signed(refx_1[3]-refx_0[3])*$signed(({1'b0,hepty[cmp_index+10'd21]})-refy_0[3])-$signed(({1'b0,heptx[cmp_index+10'd21]})-refx_0[3])*$signed(refy_1[3]-refy_0[3]);
                cp[4]<=$signed(refx_1[4]-refx_0[4])*$signed(({1'b0,hepty[cmp_index+10'd28]})-refy_0[4])-$signed(({1'b0,heptx[cmp_index+10'd28]})-refx_0[4])*$signed(refy_1[4]-refy_0[4]);
            end
        end
    end

    //quadx
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(k=0;k<10;k=k+1) quadx[k]<=21'd0;
        end
        else begin
            if(state==cal_cp)begin
                for(i=0;i<5;i=i+1)begin
                    quadx[i]<=$signed(refx_1[i]-refx_0[i]);
                end
                quadx[5]<=$signed(({1'b0,heptx[cmp_index]})-refx_0[0]);
                quadx[6]<=$signed(({1'b0,heptx[cmp_index+10'd7]})-refx_0[1]);
                quadx[7]<=$signed(({1'b0,heptx[cmp_index+10'd14]})-refx_0[2]);
                quadx[8]<=$signed(({1'b0,heptx[cmp_index+10'd21]})-refx_0[3]);
                quadx[9]<=$signed(({1'b0,heptx[cmp_index+10'd28]})-refx_0[4]);
            end
        end
    end

    //quady
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(k=0;k<10;k=k+1) quady[k]<=21'd0;
        end
        else begin
            if(state==cal_cp)begin
                for(i=0;i<5;i=i+1)begin
                    quady[i]<=$signed(refy_1[i]-refy_0[i]);
                end
                quady[5]<=$signed(({1'b0,hepty[cmp_index]})-refy_0[0]);
                quady[6]<=$signed(({1'b0,hepty[cmp_index+10'd7]})-refy_0[1]);
                quady[7]<=$signed(({1'b0,hepty[cmp_index+10'd14]})-refy_0[2]);
                quady[8]<=$signed(({1'b0,hepty[cmp_index+10'd21]})-refy_0[3]);
                quady[9]<=$signed(({1'b0,hepty[cmp_index+10'd28]})-refy_0[4]);
            end
        end
    end

    //area
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) area[j]<=21'd0;
        end
        else begin
            if(state==cal_area)begin
                area[0]<=(heptx[0]*hepty[1]-heptx[1]*hepty[0])+(heptx[1]*hepty[2]-heptx[2]*hepty[1])+(heptx[2]*hepty[3]-heptx[3]*hepty[2])+(heptx[3]*hepty[4]-heptx[4]*hepty[3])+(heptx[4]*hepty[5]-heptx[5]*hepty[4])+(heptx[5]*hepty[6]-
heptx[6]*hepty[5])+(heptx[6]*hepty[0]-heptx[0]*hepty[6])>>>1;

                area[1]<=(heptx[7]*hepty[8]-heptx[8]*hepty[7])+(heptx[8]*hepty[9]-heptx[9]*hepty[8])+(heptx[9]*hepty[10]-heptx[10]*hepty[9])+(heptx[10]*hepty[11]-heptx[11]*hepty[10])+(heptx[11]*hepty[12]-heptx[12]*hepty[11])+(heptx[12]*hepty[13]-
heptx[13]*hepty[12])+(heptx[13]*hepty[7]-heptx[7]*hepty[13])>>>1;

                area[2]<=(heptx[14]*hepty[15]-heptx[15]*hepty[14])+(heptx[15]*hepty[16]-heptx[16]*hepty[15])+(heptx[16]*hepty[17]-heptx[17]*hepty[16])+(heptx[17]*hepty[18]-heptx[18]*hepty[17])+(heptx[18]*hepty[19]-heptx[19]*hepty[18])+(heptx[19]*hepty[18]+
heptx[20]*hepty[19])+(heptx[20]*hepty[14]-heptx[14]*hepty[20])>>>1;

                area[3]<=(heptx[21]*hepty[22]-heptx[22]*hepty[21])+(heptx[22]*hepty[23]-heptx[23]*hepty[22])+(heptx[23]*hepty[24]-heptx[24]*hepty[23])+(heptx[24]*hepty[25]-heptx[25]*hepty[24])+(heptx[25]*hepty[26]-heptx[26]*hepty[25])+(heptx[26]*hepty[25]+
heptx[26]*hepty[27])+(heptx[27]*hepty[21]-heptx[21]*hepty[27])>>>1;

                area[4]<=(heptx[28]*hepty[29]-heptx[29]*hepty[28])+(heptx[29]*hepty[30]-heptx[30]*hepty[29])+(heptx[30]*hepty[31]-heptx[31]*hepty[30])+(heptx[31]*hepty[32]-heptx[32]*hepty[31])+(heptx[32]*hepty[33]-heptx[33]*hepty[32])+(heptx[33]*hepty[34]+
heptx[34]*hepty[33])+(heptx[34]*hepty[28]-heptx[28]*hepty[34])>>>1;
            end
            else if(state==bub_cal)begin
                if(area[bub_idx]<area[bub_count])begin
                    area[bub_idx]<=area[bub_count];
                    area[bub_count]<=area[bub_idx];
                end
            end
        end
    end

    //findex
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            for(j=0;j<5;j=j+1) findex[j]<=3'd0;
        end
        else begin
            if(state==bub_init)begin
                findex[0]<=3'd1;
                findex[1]<=3'd2;
                findex[2]<=3'd3;
                findex[3]<=3'd4;
                findex[4]<=3'd5;
            end
            else if(state==bub_cal)begin
                if(area[bub_idx]<area[bub_count])begin
                    findex[bub_idx]<=findex[bub_count];
                    findex[bub_count]<=findex[bub_idx];
                end
            end
        end
    end

    //show_time
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            show_time<=3'd0;
        end
        else begin
            if(state==bub_init) show_time<=3'd0;
            else if(state==out) show_time<=show_time+3'd1;
        end
    end

endmodule