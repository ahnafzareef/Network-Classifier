module uart_loopback (
    input  wire clk,
    output wire tx,
    output wire [5:0] leds   // show received byte on LEDs
);

    wire       busy;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       loopback;     // TX output wired to RX input

    assign loopback = tx;    // connect TX directly to RX

    // TX side — sends 'U' (0x55 = 01010101) repeatedly
    // 0x55 is the classic UART test byte — alternating bits
    reg start;
    reg [7:0] data;
    reg prev_busy;

    uart_tx u_tx (
        .clk   (clk),
        .start (start),
        .data  (data),
        .tx    (tx),
        .busy  (busy)
    );

    uart_rx u_rx (
        .clk        (clk),
        .rx         (loopback),
        .data       (rx_data),
        .data_valid (rx_valid)
    );

    // show bottom 6 bits of received byte on LEDs (active low)
    reg [5:0] led_reg;
    assign leds = ~led_reg;   // invert for active-low LEDs

    always @(posedge clk) begin
        prev_busy <= busy;
        start     <= 1'b0;

        // when RX gets a valid byte, show it on LEDs
        if (rx_valid && !prev_rx_valid)
            led_reg <= rx_data[5:0];
            led_reg <= rx_data[5:0];

        // send 0x55 repeatedly
        if (prev_busy && !busy) begin
            data  <= 8'h55;
            start <= 1'b1;
        end

        // kickstart
        if (!busy && !prev_busy && !start) begin
            data  <= 8'h55;
            start <= 1'b1;
        end
    end

    initial begin
        start   = 1'b0;
        data    = 8'h55;
        led_reg = 6'b010101;  // 0x55 bottom 6 bits
        prev_busy = 1'b0;
    end

endmodule