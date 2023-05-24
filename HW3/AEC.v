`timescale 1ns/10ps


module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;


//-----Your design-----//
reg [1:0] cur_state, next_state;
parameter READ = 2'd0;
parameter POST = 2'd1;
parameter POP = 2'd2;
parameter CALC = 2'd3;

reg [4:0] buff[0:15];
reg [6:0] opt[0:4]; 
reg [3:0] num_cnt;
reg [2:0] opt_cnt;
reg [4:0] cnt;
integer i;
reg [1:0] step; 
reg cmp;
reg flag;
reg iter;

always @(*) begin
    if(opt_cnt > 3'd1) begin
        case(cur_state)
            POST: begin
                case(opt[opt_cnt-1])
                    7'd16: begin  // (
                        cmp = 1'b0;
                    end
                    8'd18: begin  // *
                        if(opt[opt_cnt-2] == 7'd18) cmp = 1'b1;
                        else cmp = 1'b0;
                    end
                    8'd19: begin  // +
                        if(opt[opt_cnt-2] == 7'd16) cmp = 1'b0;
                        else cmp = 1'b1;
                    end
                    8'd20: begin  // -
                        if(opt[opt_cnt-2] == 7'd16) cmp = 1'b0;
                        else cmp = 1'b1;
                    end
                    default: cmp = 1'b0;
                endcase
            end
            POP: begin
                case(opt[opt_cnt-1])
                    7'd16: begin  // (
                        cmp = 1'b0;
                    end
                    8'd18: begin  // *
                        if(opt[opt_cnt-2] == 8'd18) cmp = 1'b1;
                        else cmp = 1'b0;
                    end
                    8'd19: begin  // +
                        if(opt[opt_cnt-2] == 8'd16) cmp = 1'b0;
                        else cmp = 1'b1;
                    end
                    8'd20: begin  // -
                        if(opt[opt_cnt-2] == 8'd16) cmp = 1'b0;
                        else cmp = 1'b1;
                    end
                    default: cmp = 1'b0;
                endcase
            end
            default: cmp = 1'b0;
        endcase
    end
    else cmp = 1'b0;
end

always @(*) begin
    if(rst) flag = 1'b0;
    else if(cur_state == POP && step == 2'd2 && cmp == 1'b1) flag = 1'b1;
    else flag = 1'b0;  
end

always @(posedge clk or posedge rst) begin
    if(rst) cur_state <= READ;
    else cur_state <= next_state;
end

always @(*) begin
    case(cur_state)
        READ: begin
            if(buff[cnt-2] == 5'd21) next_state = POST;
            else next_state = READ;
        end
        POST: begin
            if(opt_cnt == 3'd0 && buff[cnt] == 5'd21) next_state = CALC;
            else if(cmp == 1'b1) next_state = POP;
            else next_state = POST;
        end
        POP: begin
            if(step == 2'd0) next_state = POST;
            else next_state = POP;
        end
        CALC: begin
            if(step == 2'd3) next_state = READ;
            else next_state = CALC;
        end
    endcase
end


always @(posedge clk or posedge rst) begin
    if(rst) begin
        cnt <= 5'd1;
        opt_cnt <= 3'd0;
        num_cnt <= 4'd0;
        step <= 2'd0;
        result <= 7'd0;
        iter <= 1'b0;
        opt[0] <= 7'd0;
        opt[1] <= 7'd0;
        opt[2] <= 7'd0;
        opt[3] <= 7'd0;
        opt[4] <= 7'd0;
        for(i=0;i<16;i=i+1) begin
            buff[i] <= 8'd0;
        end
    end
    else begin
        case(cur_state)
            READ: begin
                if(cnt > 5'd1 && buff[cnt-2] == 5'd21) begin
                    cnt <= 5'd0;
                end 
                else begin
                    cnt <= cnt + 5'd1;
                    if(ascii_in >= 8'd48 && ascii_in <= 8'd57) buff[cnt-1] <= ascii_in - 8'd48;
                    else if(ascii_in >= 8'd97 && ascii_in <= 8'd102) buff[cnt-1] <= ascii_in - 8'd87;
                    else if(ascii_in >= 8'd40 && ascii_in < 8'd44) buff[cnt-1] <= ascii_in - 8'd24;
                    else if(ascii_in == 8'd45) buff[cnt-1] <= ascii_in - 8'd25; 
                    else if(ascii_in == 8'd61) buff[cnt-1] <= ascii_in - 8'd40;
                end 
            end
            POST: begin
                if(cmp == 1'b1) step <= 2'd1;
                case(buff[cnt])
                    5'd16, 5'd17, 5'd18, 5'd19, 5'd20: begin  // ()*+-
                        case(buff[cnt]) 
                            5'd17: begin  // )
                                if(opt[opt_cnt-1] != 5'd16) begin
                                    buff[num_cnt] <= opt[opt_cnt-1];
                                    opt[opt_cnt-1] <= 7'd0; 
                                    num_cnt <= num_cnt + 4'd1;
                                    opt_cnt <= opt_cnt - 3'd1;
                                end
                                else begin  
                                    opt_cnt <= opt_cnt - 3'd1;
                                    opt[opt_cnt-1] <= 7'd0;
                                    if(cmp == 1'b0) cnt <= cnt + 5'd1;
                                end
                            end
                            default: begin  // (*+-
                                opt[opt_cnt] <= buff[cnt];
                                opt_cnt <= opt_cnt + 3'd1;
                                if(cmp == 1'b0) cnt <= cnt + 5'd1;
                            end
                        endcase
                    end
                    5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9, 5'd21: begin  // 0~9 =
                        if(buff[cnt] == 5'd21) begin  // =
                            if(opt_cnt != 4'd0) begin
                                buff[num_cnt] <= opt[opt_cnt-1];
                                num_cnt <= num_cnt + 4'd1;
                                opt_cnt <= opt_cnt - 3'd1;
                            end
                            else cnt <= 4'd0;
                        end
                        else begin  // 0~9
                            buff[num_cnt] <= buff[cnt];
                            num_cnt <= num_cnt + 4'd1;
                            if(cmp == 1'b0) cnt <= cnt + 5'd1;
                        end
                    end
                    5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15: begin  // a~f
                        buff[num_cnt] <= buff[cnt];
                        num_cnt <= num_cnt + 4'd1;
                        if(cmp == 1'b0) cnt <= cnt + 4'd1;
                    end
                endcase
            end
            POP: begin
                case(step)
                    2'd1: begin
                        if(buff[cnt][4] != 1'b1) begin
                            buff[num_cnt-1] <= opt[opt_cnt-2];
                            opt[opt_cnt-2] <= opt[opt_cnt-1];
                            opt[opt_cnt-1] <= 7'd0;
                            opt_cnt <= opt_cnt - 3'd1;
                            step <= 2'd2;
                        end
                        else if(buff[cnt][4] == 1'b1 && iter == 1'b0) begin
                            buff[num_cnt] <= opt[opt_cnt-3];
                            opt[opt_cnt-3] <= opt[opt_cnt-2];
                            opt[opt_cnt-1] <= 7'd0;
                            opt_cnt <= opt_cnt - 3'd2;
                            num_cnt <= num_cnt + 4'd1;
                            step <= 2'd2;
                            iter <= 1'b1;
                        end
                        else if(buff[cnt][4] == 1'b1 && iter == 1'b1) begin
                            buff[num_cnt] <= opt[opt_cnt-2];
                            opt[opt_cnt-2] <= opt[opt_cnt-1];
                            opt[opt_cnt-1] <= 7'd0;
                            opt_cnt <= opt_cnt - 3'd1;
                            num_cnt <= num_cnt + 4'd1;
                            step <= 2'd2;
                        end
                    end
                    2'd2: begin
                        if(cmp == 1'b1) step <= 2'd1;
                        else begin
                            step <= 2'd0;
                            iter <= 1'b0;
                        end
                        if(flag == 1'b1 && iter == 1'b0) num_cnt <= num_cnt + 4'd1;
                    end
                endcase
            end
            CALC: begin
                case(step)
                    2'd0: begin
                        if(buff[cnt][4] != 1'b1) begin
                            opt[opt_cnt] <= buff[cnt];
                            cnt <= cnt + 4'd1;
                            opt_cnt <= opt_cnt + 3'd1;
                        end
                        else begin
                            opt[opt_cnt] <= buff[cnt];
                            step <= 2'd1;
                            if(cnt != num_cnt - 4'd1) cnt <= cnt + 4'd1;
                        end
                    end
                    2'd1: begin
                        case(opt[opt_cnt])
                            7'd18: result <= opt[opt_cnt-2] * opt[opt_cnt-1];    // *
                            7'd19: result <= opt[opt_cnt-2] + opt[opt_cnt-1];    // +
                            7'd20: result <= opt[opt_cnt-2] - opt[opt_cnt-1];    // -
                        endcase
                        opt_cnt <= opt_cnt - 3'd1;
                        step <= 2'd2;
                    end
                    2'd2: begin
                        if(opt_cnt == 4'd1 && cnt == num_cnt - 4'd1) begin
                            step <= 2'd3;
                            valid <= 1'b1;
                            opt_cnt <= 3'd0;
                            cnt <= 5'd1;
                        end
                        else begin
                            opt[opt_cnt-1] <= result;
                            step <= 2'd0;
                        end
                    end
                    2'd3: begin
                        valid <= 1'b0;
                        result <= 7'd0;
                        step <= 2'd0;
                        num_cnt <= 4'd0;
                        opt[0] <= 7'd0;
                        opt[1] <= 7'd0;
                        opt[2] <= 7'd0;
                        opt[3] <= 7'd0;
                        opt[4] <= 7'd0;
                        for(i=0;i<16;i=i+1) begin
                            buff[i] <= 8'd0;
                        end
                    end
                endcase
            end
        endcase
    end
end

endmodule
