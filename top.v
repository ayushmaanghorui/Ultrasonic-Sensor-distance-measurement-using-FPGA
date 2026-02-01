/*
Module HC_SR04 Ultrasonic Sensor

This module will detect objects present in front of the range, and give the distance in mm.

Input:  clk_50M - 50 MHz clock
        reset   - reset input signal (Use negative reset)
        echo_rx - receive echo from the sensor

Output: trig    - trigger sensor for the sensor
        op     -  output signal to indicate object is present.
        distance_out - distance in mm, if object is present.
*/

// module Declaration
module t1b_ultrasonic(
    input clk_50M, reset, echo_rx,
    output reg trig,
    output op,
    output wire [15:0] distance_out
);

initial begin
    trig = 0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

parameter TRIG_CYCLES  = 501;   //total count for trigger pulse    
parameter STAB_CYCLES  = 50;    //total count for the initial 1us delay 
parameter DELAY_CYCLES = 600_000; //total count for 12 ms delay between two trigger pulse   

parameter INIT       = 3'd0,	//defined states for the trigger and echo pins
          TRIG_STATE = 3'd1,
          ECHO_WAIT  = 3'd2,
          MEASURE    = 3'd3,
          DELAY      = 3'd4;

reg [2:0] state = INIT;      	//these are the internal registers that will maintain the states and different count values    
reg [19:0] counter = 0;          
reg [16:0] echo_counter = 0;     
reg [15:0] distance_reg = 0;     

assign distance_out = distance_reg;			// since distance_out and op are only output wire and ouput respectively we have assign them to certain registers which will be storing the values during FSM logic
assign op = (distance_reg <= 16'd70) ? 1'b1 : 1'b0; //obstacle detection logic

always @(posedge clk_50M or negedge reset) 
begin
    if(!reset) begin   //active low asynchronous reset which will reset all the values
        state <= INIT;
        counter <= 0;
        echo_counter <= 0;
        trig <= 0;
        distance_reg <= 0;
    end
    else begin
        case(state)		// the FSM logic starts from here
            INIT: begin						
                trig <= 0;		// this is the initial state which is defined to initialize a 1us delay. Trigger will be low during this duration and it is called only one time
                if(counter < STAB_CYCLES-1)
                    counter <= counter + 1;		//counting for 1us delay
                else begin
                    counter <= 0;
                    state <= TRIG_STATE;		//when the delay is added, move on to next state
                end
            end

            TRIG_STATE: begin
                trig <= (counter > 0) ? 1 : 0;	//trigger has to stay high for 10us and after that it will get low. So this if condition performs this operation.
                if(counter < TRIG_CYCLES)
                    counter <= counter + 1;		//counting for 10 us duration
                else begin
                    counter <= 0;   //moves on to next state 
                    trig <= 0;
                    state <= ECHO_WAIT;
                end
            end

            ECHO_WAIT: begin
                if(echo_rx) begin		
                    echo_counter <= 0;  //this state will wait for echo signal to go high. If it goes high then it will move to next state to measure the echo width
                    state <= MEASURE;	
                end
            end

            MEASURE: begin
                if(echo_rx) begin
                    echo_counter <= echo_counter + 1;		//calculating the echo width
                end
                else begin
                    
                    distance_reg <= ((echo_counter ) / 294) - 1; //calculating the distance in mm using the desired formula.
                    state <= DELAY;
                    counter <= 0; 
                end
            end

            DELAY: begin
                if(counter < DELAY_CYCLES-1-echo_counter+50) //since  the time gap between two trigger pulse should be 12 ms, but when the state is Measure , it is consuming more time hence increasing the delay.
                    counter <= counter + 1;//so to compensate the additional time we are substracting the echo_counter value.
                else begin
                    counter <= 0;
                    state <= TRIG_STATE;  //next trigger pulse
                end
            end
        endcase
    end
end

/*
Add your logic here
*/

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
