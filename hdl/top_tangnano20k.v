// ============================================================
//  Tang Nano 20K 用のトップ (ボードと CPU をつなぐだけ)
// ============================================================
module top_tangnano20k #(
    parameter CLK_HZ         = 27_000_000,
    parameter CPU_HZ         = 1_000,   // CPU は 1秒に 1000 命令
    parameter BTN_ACTIVE_LOW = 0        // ボタンが押して 0 になる基板なら 1
) (
    input  wire       clk,       // 27MHz
    input  wire       s1,
    input  wire       s2,
    output wire [5:0] led_n      // オンボードLED (0 で点灯)
);
    // ---- 電源を入れた直後のリセット --------------------------
    reg [3:0] rst_cnt = 0;
    wire      reset   = ~rst_cnt[3];
    always @(posedge clk) if (reset) rst_cnt <= rst_cnt + 1'b1;

    // ---- CPU をゆっくり動かす (1000分の1秒ごとに step=1) ----
    localparam DIV = CLK_HZ / CPU_HZ;
    reg [31:0] div_cnt = 0;
    wire       step    = (div_cnt == DIV - 1);
    always @(posedge clk) div_cnt <= step ? 0 : div_cnt + 1;

    // ---- ボタン (クロックにそろえる) ------------------------
    reg [1:0] btn_s1, btn_s2;
    always @(posedge clk) begin
        btn_s1 <= {s2, s1} ^ (BTN_ACTIVE_LOW ? 2'b11 : 2'b00);
        btn_s2 <= btn_s1;
    end

    // ---- CPU ------------------------------------------------
    wire [5:0] led;
    tta8 cpu (
        .clk(clk), .reset(reset), .step(step),
        .btn(btn_s2), .led(led)
    );

    assign led_n = ~led;
endmodule
