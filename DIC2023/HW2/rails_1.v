module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output    valid;
output  reg  result; 

reg [3:0] cnt; //count data
reg [3:0] buff[0:10];  //buff all data
reg [3:0] i, j;
reg [3:0] index, max;
wire flag;
assign flag = (index == buff[cnt-j])? 1 : 0;
//wire [3:0] num;

reg [2:0] cur_state, next_state;
parameter IDLE = 3'd0;
parameter READ = 3'd1;
parameter PROC = 3'd2;
parameter CHECK = 3'd3;
parameter OUT = 3'd4;

always@(posedge clk or posedge reset)
begin
	if(reset) cur_state <= IDLE;
	else cur_state <= next_state;
end

always@(*)
begin
    case(cur_state)
	IDLE:
	begin
		if(cnt == 4'd1) next_state = READ;
        else next_state = READ;
    end
	READ:
	begin
	    if(cnt == buff[0]) next_state = PROC;
		else next_state = READ;
    end
	PROC:
	begin
		if(buff[cnt] > max || buff[cnt] == index) next_state = CHECK;
        else next_state = OUT;
    end
    CHECK:
    begin
        if(j == cnt - 4'd1 && cnt != buff[0] && flag == 4'd0) next_state = PROC;
        else if(j == cnt - 4'd1 && cnt == buff[0] && flag == 4'd0) next_state = OUT;
        else next_state = CHECK;
    end
    OUT:
	begin
	    next_state = IDLE;
	end
    default:
    begin
        next_state = IDLE;
    end
	endcase
end

assign valid = (cur_state == OUT)? 1 : 0;

always@(posedge clk or posedge reset)
begin
	if(reset)
	begin
	    cnt <= 4'd0;
		//result <= 1'b0;
		max <= 4'd0;
		index <= 4'd0;
		for(i=0; i<11; i=i+1) 
		begin
		    buff[i] <= 4'd0;
	 	end
	end
	else
	begin
	    case(cur_state)
        IDLE:
        begin
            for(i=0; i<11; i=i+1) 
		    begin
		        buff[i] <= 4'd0;
	 	    end
            //result <= 1'b0;
            buff[0] <= data;
            cnt <= 4'd1;
        end
	    READ:
	    begin
		    buff[cnt] <= data;
            if(cnt == buff[0]) 
		    begin
		        cnt <= 4'd2;
		        index <= buff[1] - 4'd1;
			    max <= buff[1];
		    end
            else 
		    begin
			    cnt <= cnt + 4'd1;
	        end
            //j <= 4'd1;
	    end
		PROC:
	  	begin
            if(buff[cnt] > max) 
            begin
                if(index == 0 && buff[cnt] == buff[cnt-1] + 1)
                begin
                    max <= buff[cnt];
                    index <= 4'd0;
                end
                else 
                begin
                    max <= buff[cnt];
                    index <= buff[cnt] - 4'd1;
                end
            end
            else if(buff[cnt] == index)
            begin
                index <= index - 4'd1;
            end
            j <= 4'd1;
        end
        CHECK:
        begin
            j <= j + 4'd1;
            if(index == buff[cnt-j])
            begin
                index <= index - 4'd1;
            end
            if(flag)
            begin
                j <= 4'd1;
            end
            else if(j == cnt - 4'd1 && flag == 1'b0)
            begin
                j <= 4'd1;
                cnt <= cnt + 4'd1;
            end
        end
		//OUT:
		//begin
			 //if((cnt == buff[0])) result <= 1'b1;
			//else result <= 1'b0;
		//end
		endcase
	end
end

always@(*)
begin
    if(cur_state == OUT && cnt == buff[0] + 4'd1) result = 1'b1;
    else result = 1'b0;
end
endmodule