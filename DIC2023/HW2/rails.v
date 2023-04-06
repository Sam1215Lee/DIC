module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output    valid;
output    reg   result; 

reg [3:0] cnt; //count data
reg [3:0] buff[0:10];  //buff all data
reg [3:0] i, j;
reg [3:0] index, max;
//wire [3:0] num;

reg [1:0] cur_state, next_state;
parameter IDLE = 2'd0;
parameter READ = 2'd1;
parameter PROC = 2'd2;
parameter OUT = 2'd3;

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
		if((buff[cnt] > max || buff[cnt] == index) && cnt < buff[0]) next_state = PROC;
	    else if((cnt == buff[0])) next_state = OUT;
	    else next_state = OUT;
    end
    OUT:
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
		result <= 1'b0;
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
            result <= 1'b0;
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
            j <= 4'd1;
	    end
		PROC:
	  	begin
            cnt <= cnt + 4'd1;
			if(index == 4'd0 && buff[cnt] == buff[cnt-1] + 4'd1)
			begin
				index <= 4'd0;
				max <= buff[cnt];
			end
			else if(buff[cnt] > max)
		    begin
			    max <= buff[cnt];
                index <= buff[cnt] - 4'd1;   
				for(j=1; j<cnt; j=j+1)
                begin
                    if(index == buff[cnt-j]) 
                    begin
                        index <= index - 4'd1;
                    end
                end         
		    end
            if(index == buff[cnt])
            begin
                index <= index - 4'd1;
				for(j=1; j<cnt; j=j+1)
                begin
                    if(index == buff[cnt-j]) 
                    begin
                        index <= index - 4'd1;
                    end
                end
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
    if(cur_state == OUT && cnt == buff[0] + 4'd1) result <= 1'b1;
    else result <= 1'b0;
end
endmodule