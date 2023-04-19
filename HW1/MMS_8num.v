`include "MMS_4num.v"
module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output reg [7:0] result; 

wire [7:0] temp1;
wire [7:0] temp2;
wire cmp = (temp1 < temp2) ? 1 : 0;

MMS_4num MMS1(.result(temp1), .select(select), .number0(number0), .number1(number1), .number2(number2), .number3(number3));
MMS_4num MMS2(.result(temp2), .select(select), .number0(number4), .number1(number5), .number2(number6), .number3(number7));

always@(*)
begin
    case({select,cmp})
	 2'b00: result = temp1;
	 2'b01: result = temp2;
	 2'b10: result = temp2;
	 2'b11: result = temp1; 
	 endcase
end


endmodule