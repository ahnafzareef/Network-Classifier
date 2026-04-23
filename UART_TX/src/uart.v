module uart_tx (
    input  wire       clk,
    input  wire       start,    // pulse high for 1 cycle to send
    input  wire [7:0] data,     // byte to send
    output reg        tx,       // serial output wire
    output reg        busy      // high while transmitting
);

    // 27MHz / 115200 baud = 234 cycles per bit
    localparam CLKS_PER_BIT = 234;

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0]  state;
    reg [7:0]  clk_count;   // counts up to CLKS_PER_BIT
    reg [2:0]  bit_index;   // which data bit we're sending (0-7)
    reg [7:0]  tx_data;     // latched copy of data to send

    always @(posedge clk) begin
        case (state)

            IDLE: begin
                tx        <= 1'b1;   // line high when idle
                busy      <= 1'b0;
                clk_count <= 8'd0;
                bit_index <= 3'd0;

                if (start) begin
                    tx_data <= data; // latch the data now
                    state   <= START;
                    busy    <= 1'b1;
                end
            end

            START: begin
                tx <= 1'b0;          // pull line low — start bit

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 8'd0;
                    state     <= DATA;
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

            DATA: begin
                tx <= tx_data[bit_index];   // send current bit

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 8'd0;

                    if (bit_index == 3'd7) begin
                        bit_index <= 3'd0;
                        state     <= STOP;
                    end else begin
                        bit_index <= bit_index + 3'd1;
                    end
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

            STOP: begin
                tx <= 1'b1;          // stop bit — line high

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 8'd0;
                    state     <= IDLE;
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

        endcase
    end

endmodule

module uart_rx (
    input  wire       clk,
    input  wire       rx,          // serial input
    output reg  [7:0] data,        // received byte
    output reg        data_valid   // pulses high for 1 cycle when byte ready
);

    localparam CLKS_PER_BIT     = 234;
    localparam HALF_CLKS        = 117;  // half bit period

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;
    reg [7:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] rx_data;    // shift register builds up received byte
    reg       rx_sync;    // synchronized rx input

    always @(posedge clk) begin
        // synchronize rx input to our clock domain
        // (avoids metastability — more on this below)
        rx_sync <= rx;

        // default — only pulses high for exactly one cycle
        data_valid <= 1'b0;

        case (state)

            IDLE: begin
                clk_count <= 8'd0;
                bit_index <= 3'd0;

                // watch for line going low — start bit
                if (rx_sync == 1'b0)
                    state <= START;
            end

            START: begin
                // wait until we're in the middle of the start bit
                if (clk_count == HALF_CLKS - 1) begin
                    // verify it's still low — not just a glitch
                    if (rx_sync == 1'b0) begin
                        clk_count <= 8'd0;
                        state     <= DATA;
                    end else begin
                        // was a glitch — go back to idle
                        state <= IDLE;
                    end
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

            DATA: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 8'd0;

                    // sample the bit into the shift register
                    // LSB comes first so shift in from the top
                    rx_data[bit_index] <= rx_sync;

                    if (bit_index == 3'd7) begin
                        bit_index <= 3'd0;
                        state     <= STOP;
                    end else begin
                        bit_index <= bit_index + 3'd1;
                    end
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

            STOP: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    // stop bit should be high — verify it
                    if (rx_sync == 1'b1) begin
                        data       <= rx_data;   // output the complete byte
                        data_valid <= 1'b1;      // pulse valid for 1 cycle
                    end
                    // if stop bit wrong, we just drop the byte silently
                    clk_count <= 8'd0;
                    state     <= IDLE;
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

        endcase
    end

endmodule