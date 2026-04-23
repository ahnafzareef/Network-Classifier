module fsm_example (
    input  wire clk,
    input  wire button,    // active low on Tang Nano 9K
    output reg  led
);

    // Define states as parameters (named constants)
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;

    reg state;  // 1 bit holds our current state

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                led <= 1'b1;         // LED off (active low)
                if (!button)         // button pressed (active low = 0 when pressed)
                    state <= ACTIVE;
            end

            ACTIVE: begin
                led <= 1'b0;         // LED on
                if (!button)         // button still held
                    state <= IDLE;
            end
        endcase
    end

endmodule