module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output reg IROM_EN;
output reg [5:0] IROM_A;
output wire IRB_RW;
output reg [7:0] IRB_D;
output reg [5:0] IRB_A;
output reg busy;
output reg done;

reg[6:0] cnt;
reg[1:0] cur,next;
reg[7:0] buff[0:63];
reg[2:0] x,y;
reg[2:0] cmd_reg;
wire[9:0] avg_reg;
wire[5:0] pos;

parameter read = 2'd0;
parameter proc = 2'd1;
parameter out = 2'd2;

parameter write = 3'd0;
parameter up = 3'd1;
parameter down = 3'd2;
parameter left = 3'd3;
parameter right = 3'd4;
parameter avg = 3'd5;
parameter mirx = 3'd6;
parameter miry = 3'd7;

always@(*) // next state
begin
    case(cur)
    read:
    begin
        if(cnt == 7'd64)next = proc;
        else next = read;
    end
    proc:
    begin
        if(cmd_reg == write)next = out;
        else next = proc;
    end
    out:
    begin
        if(cnt == 7'd63)next = read;
        else next = out;
    end
	 default:
	 begin
		  next = read;
	 end
    endcase
end

always@(posedge reset or posedge clk) // state reg
begin
    if(reset) cur <= read;
    else cur <= next;
end

always@(posedge reset or posedge clk) // IROM_EN
begin
    if(reset)IROM_EN <= 0;
    else if(cnt == 7'd64)IROM_EN <= 1;
end

always@(posedge reset or posedge clk) // cnt
begin
    if(reset) cnt <= 7'd0;
    else if(cur == read)
    begin
        if(cnt == 7'd64)
		  begin
				cnt <= 7'd0;
				busy <= 1'b0;
		  end
        else cnt <= cnt + 7'd1;
    end
    else if(cur == out)
    begin
        if(cnt == 7'd63)
		  begin 
				cnt <= 7'd0;
				busy <= 1'b0;
		  end
        else cnt <= cnt + 7'd1;
    end
end

always@(*) // IROM_A
begin
    if(cur == read)IROM_A = cnt[5:0];
	 else IROM_A = 6'd0;
end

always@(posedge clk) // read IROM_Q
begin
    if(cur == read)
    begin
        if(cnt>7'd0)buff[cnt-7'd1] <= IROM_Q;
    end
end

always@(posedge clk) // cmd_reg
begin
    if(cmd_valid) // deletable
    begin
		  busy <= 1'b1;
        cmd_reg <= cmd;
    end
end

always@(posedge reset or posedge clk) // x y 
begin
    if(reset)
    begin
        x <= 3'd4;
        y <= 3'd4;
		  busy <= 1'b1;
    end
    else if(cur == proc && busy)
    begin
			if(cmd_reg!=write)busy <= 1'b0;
        case(cmd_reg)
        up: if(y>3'd1) y <= y - 3'd1;
        down: if(y<3'd7) y <= y + 3'd1;
        left: if(x>3'd1) x <= x - 3'd1; 
        right: if(x<3'd7) x <= x + 3'd1; 
        avg:
        begin
            buff[pos] <= avg_reg[9:2];
            buff[pos-1] <= avg_reg[9:2];
            buff[pos-8] <= avg_reg[9:2];
            buff[pos-9] <= avg_reg[9:2];
        end
        miry:
        begin
            buff[pos] <= buff[pos-1];
            buff[pos-1] <= buff[pos];
            buff[pos-8] <= buff[pos-9];
            buff[pos-9] <= buff[pos-8];
        end
        mirx:
        begin
            buff[pos] <= buff[pos-8];
            buff[pos-1] <= buff[pos-9];
            buff[pos-8] <= buff[pos];
            buff[pos-9] <= buff[pos-1];
        end
        endcase
    end
end

always@(*) // IRB_A IRB_D
begin
    if(reset)
    begin
        IRB_A = 0;
        IRB_D = 0;
    end
	 else if(cur == out)
    begin
        IRB_A = cnt;
        IRB_D = buff[cnt];
    end
	 else
	 begin
        IRB_A = 0;
        IRB_D = 0;
    end
end

always@(posedge clk) // done
begin
    if((cur == out) && (cnt == 7'd63))done <= 1'b1;
end

assign pos = {y,x};
assign avg_reg = buff[pos]+buff[pos-1]+buff[pos-8]+buff[pos-9];
assign IRB_RW = (cur==out)?0:1;

endmodule

