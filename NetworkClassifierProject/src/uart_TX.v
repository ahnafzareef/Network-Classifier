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