module uart_echo (
    input  wire clk,
    input  wire rx,
    output wire tx,
    output wire [5:0] leds
);

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;

    reg        tx_start;
    reg [7:0]  tx_data;
    reg        prev_valid;

    uart_rx u_rx (
        .clk        (clk),
        .rx         (rx),
        .data       (rx_data),
        .data_valid (rx_valid)
    );

    uart_tx u_tx (
        .clk   (clk),
        .start (tx_start),
        .data  (tx_data),
        .tx    (tx),
        .busy  (tx_busy)
    );

    // show last received byte on LEDs (active low)
    reg [7:0] last_byte;
    assign leds = ~last_byte[5:0];

    always @(posedge clk) begin
        prev_valid <= rx_valid;
        tx_start   <= 1'b0;     // default no start pulse

        // detect rising edge of rx_valid — new byte just arrived
        if (rx_valid && !prev_valid) begin
            last_byte <= rx_data;   // show it on LEDs

            // only echo if TX is free
            if (!tx_busy) begin
                tx_data  <= rx_data;
                tx_start <= 1'b1;
            end
        end
    end

    initial begin
        tx_start   = 1'b0;
        tx_data    = 8'd0;
        prev_valid = 1'b0;
        last_byte  = 8'd0;
    end

endmodule