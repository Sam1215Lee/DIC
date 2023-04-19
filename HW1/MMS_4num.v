module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output reg [7:0] result; 
 
wire [7:0] max1 = (number0 > number1) ? number0: number1;
wire [7:0] max2 = (number2 > number3) ? number2: number3;
wire [7:0] max = (max1 > max2) ? max1 : max2;
wire [7:0] min1 = (number0 < number1) ? number0: number1;
wire [7:0] min2 = (number2 < number3) ? number2: number3;
wire [7:0] min = (min1 < min2) ? min1 : min2;


always@(*)
begin
    if(!select)
	  result = max;
	 else
	  result = min;
end

endmodule