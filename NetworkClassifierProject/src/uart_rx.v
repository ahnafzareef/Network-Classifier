module uart_rx (
    input  wire       clk,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        data_valid
);

    localparam CLKS_PER_BIT = 234;
    localparam HALF_CLKS    = 117;

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [7:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] rx_data;
    reg       rx_meta;
    reg       rx_sync;

    always @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;

        data_valid <= 1'b0;

        case (state)

            IDLE: begin
                clk_count <= 8'd0;
                bit_index <= 3'd0;

                if (rx_sync == 1'b0)
                    state <= START;
            end

            START: begin
                if (clk_count == HALF_CLKS - 1) begin
                    if (rx_sync == 1'b0) begin
                        clk_count <= 8'd0;
                        state     <= DATA;
                    end else begin
                        state <= IDLE;
                    end
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

            DATA: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count          <= 8'd0;
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
                    if (rx_sync == 1'b1) begin
                        data       <= rx_data;
                        data_valid <= 1'b1;
                    end
                    clk_count <= 8'd0;
                    state     <= IDLE;
                end else begin
                    clk_count <= clk_count + 8'd1;
                end
            end

        endcase
    end

    initial begin
        state      = IDLE;
        clk_count  = 8'd0;
        bit_index  = 3'd0;
        rx_data    = 8'd0;
        data_valid = 1'b0;
        rx_meta    = 1'b1;
        rx_sync    = 1'b1;
    end

endmodule