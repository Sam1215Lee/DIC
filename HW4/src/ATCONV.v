`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output 	    busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

//=================================================
//            write your design below
//=================================================
	
	reg [2:0] cur_state, next_state;
	localparam IDLE = 3'd0;
	localparam READ_IMAGE = 3'd1;
	localparam WRITE_MEM0 = 3'd2;
	localparam READ_MEM0 = 3'd3;
	localparam WRITE_MEM1 = 3'd4;
	localparam FINISH = 3'd5;

	reg [5:0] col, row;
	reg [4:0] tempX_L0, tempY_L0;
	reg [3:0] cnt;
	
	wire [3:0] is_pad;
	assign is_pad[0] = (col < 6'd2);
	assign is_pad[1] = (col > 6'd61);
	assign is_pad[2] = (row < 6'd2);
	assign is_pad[3] = (row > 6'd61);

	assign busy = !(cur_state == FINISH || cur_state == IDLE);
	
    reg signed [12:0] img_buff[0:8];
	wire signed [29:0] conv_sum;
    assign conv_sum = (img_buff[4]<<4)-(img_buff[0])-(img_buff[1]<<1)-(img_buff[2])-(img_buff[3]<<2)-(img_buff[5]<<2)-(img_buff[6])-(img_buff[7]<<1)-(img_buff[8])-4'd12;

	reg [12:0] max;

	always @(posedge clk or posedge reset) begin
		if(reset) cur_state <= IDLE; 
		else cur_state <= next_state;
	end
	
	always @(*) begin
		case(cur_state)
			IDLE: begin
				if(ready == 1'b1) next_state = READ_IMAGE;
				else next_state = IDLE;
			end
			READ_IMAGE: begin
				if(cnt == 4'd10) next_state = WRITE_MEM0;
				else next_state = READ_IMAGE;
			end
			WRITE_MEM0: begin
				if(row == 6'd63 && col == 6'd63) next_state = READ_MEM0;
				else next_state = READ_IMAGE;
			end
			READ_MEM0: begin
				if(cnt == 4'd5) next_state = WRITE_MEM1;
				else next_state = READ_MEM0;
			end
			WRITE_MEM1: begin
				if(row == 6'd62 && col == 6'd62) next_state = FINISH;
				else next_state = READ_MEM0;
			end
			FINISH: begin
				next_state = IDLE;
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	always @(posedge clk or posedge reset) begin
		if(reset) begin
			col <= 6'd0;
			row <= 6'd0;
			cnt <= 4'd0;
			tempX_L0 <= 5'd0;
			tempY_L0 <= 5'd0;
			csel <= 1'b0;
			cwr <= 1'b0;
			crd <= 1'b0;
			max <= 13'd0;
			iaddr <= 12'd0;
			caddr_rd <= 12'd0;
			caddr_wr <= 12'd0;
			cdata_wr <= 13'd0;
		end
		else begin
			case(cur_state)
				READ_IMAGE: begin
					case(cnt)
						4'd0: begin  // {row-2, col-2}
							case({is_pad[2], is_pad[0]})
								2'b00: iaddr <= {row-6'd2, col-6'd2};
								2'b01: iaddr <= {row-6'd2, 6'd0};
								2'b10: iaddr <= {6'd0, col-6'd2};
								2'b11: iaddr <= {6'd0, 6'd0};
						    endcase
						end
						4'd1: begin  // {row-2, col}
							if(is_pad[2] == 1'b1) iaddr <= {6'd0, col};
							else iaddr <= {row-6'd2, col};
                            img_buff[0] <= idata;
						end
						4'd2: begin  // {row-2, col+2}
							case({is_pad[2], is_pad[1]})
								2'b00: iaddr <= {row-6'd2, col+6'd2};
								2'b01: iaddr <= {row-6'd2, 6'd63};
								2'b10: iaddr <= {6'd0, col+6'd2};
								2'b11: iaddr <= {6'd0, 6'd63};
							endcase
                            img_buff[1] <= idata;
						end
						4'd3: begin  // {row, col-2}
							if(is_pad[0] == 1'b1) iaddr <= {row, 6'd0};
							else iaddr <= {row, col-6'd2};
                            img_buff[2] <= idata;
						end
						4'd4: begin  // {row, col}
							iaddr <= {row, col};
                            img_buff[3] <= idata;
						end
						4'd5: begin  // {row, col+2}
							if(is_pad[1] == 1'b1) iaddr <= {row, 6'd63};
							else iaddr <= {row, col+6'd2};
                            img_buff[4] <= idata;
						end
						4'd6: begin  // {row+2, col-2}
							case({is_pad[3], is_pad[0]})
								2'b00: iaddr <= {row+6'd2, col-6'd2};
								2'b01: iaddr <= {row+6'd2, 6'd0};
								2'b10: iaddr <= {6'd63, col-6'd2};
								2'b11: iaddr <= {6'd63, 6'd0};
							endcase
                            img_buff[5] <= idata;
						end
						4'd7: begin  // {row+2, col}
							if(is_pad[3] == 1'b1) iaddr <= {6'd63, col};
							else iaddr <= {row+6'd2, col};
                            img_buff[6] <= idata;
						end
						4'd8: begin  // {row+2, col+2}
							case({is_pad[3], is_pad[1]})
								2'b00: iaddr <= {row+6'd2, col+6'd2};
								2'b01: iaddr <= {row+6'd2, 6'd63};
								2'b10: iaddr <= {6'd63, col+6'd2};
								2'b11: iaddr <= {6'd63, 6'd63};
							endcase
                            img_buff[7] <= idata;
						end
						4'd9: begin
                            img_buff[8] <= idata;
						end
						4'd10: begin
							caddr_wr <= {row, col};
							cdata_wr <= (conv_sum[16] || conv_sum[16:4] <= 13'd11)? 13'd0 : conv_sum[16:4]-13'd11;
						end
					endcase

					if(cnt == 10) begin
						cnt <= 4'd0;
						cwr <= 1'b1;
						csel <= 1'b0;
					end
					else 
						cnt <= cnt + 4'd1;
				end
				WRITE_MEM0: begin
					cwr <= 1'b0;
					
					if(col == 6'd63) begin
						col <= 6'd0;
						row <= row + 6'd1;
					end
					else 
						col <= col + 6'd1;

					if(row == 6'd63 && col == 6'd63) begin
						row <= 6'd0;
						col <= 6'd0;
						cwr <= 1'b0;
						crd <= 1'b1;
						csel <= 1'b0;
					end
				end
				READ_MEM0: begin
					case(cnt)
						4'd0: begin
							caddr_rd <= {row, col};
							max <= 13'd0;
						end
						4'd1: begin
							caddr_rd <= {row, col+6'd1};
							max <= cdata_rd;
						end
						4'd2: begin
							caddr_rd <= {row+6'd1, col};
							max <= (max > cdata_rd)? max : cdata_rd; 
						end
						4'd3: begin
							caddr_rd <= {row+6'd1, col+6'd1};
							max <= (max > cdata_rd)? max : cdata_rd; 
						end
						4'd4: begin
							max <= (max > cdata_rd)? max : cdata_rd;
						end
						4'd5: begin 
							caddr_wr <= {tempY_L0, tempX_L0};
							if(max != 13'd0) begin
								if(max[3:0] != 13'd0) cdata_wr <= (max[12:4] + 1) << 4;
								else cdata_wr <= max[12:4] << 4;
							end
							else 
								cdata_wr <= 13'd0;
						end
					endcase

					if(cnt == 4'd5) begin
						cnt <= 4'd0;
						cwr <= 1'b1;
						crd <= 1'b0;
						csel <= 1'b1;
					end
					else 
						cnt <= cnt + 4'd1;
				end
				WRITE_MEM1: begin
					if(tempX_L0 == 5'd31) begin
						tempY_L0 <= tempY_L0 + 5'd1;
						tempX_L0 <= 5'd0;
					end
					else 
						tempX_L0 <= tempX_L0 + 5'd1;
					
					if(col == 6'd62) begin
						col <= 6'd0;
						row <= row + 6'd2;
					end
					else
						col <= col + 6'd2;
					
					if(row == 6'd62 && col == 6'd62) begin
						cwr <= 1'b0;
						crd <= 1'b0;
						csel <= 1'b0;
					end
					else begin
						cwr <= 1'b0;
						crd <= 1'b1;
						csel <= 1'b0;
					end
				end
				FINISH: begin
					row <= 6'd0;
					col <= 6'd0;
					tempX_L0 <= 5'd0;
					tempY_L0 <= 5'd0;
				end
			endcase
		end
	end

endmodule
