// Expand $modfloor into $div / $mul / $sub (all supported by SAW yosys_import).
// Identity: a mod b = a - (a div b) * b, valid for floor div/mod.
(* techmap_celltype = "$modfloor" *)
module _90_modfloor_expand (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH-1:0] q;
  wire [A_WIDTH-1:0] prod;
  $div #(.A_SIGNED(A_SIGNED), .B_SIGNED(B_SIGNED), .A_WIDTH(A_WIDTH), .B_WIDTH(B_WIDTH), .Y_WIDTH(A_WIDTH)) u_div (.A(A), .B(B), .Y(q));
  $mul #(.A_SIGNED(A_SIGNED), .B_SIGNED(B_SIGNED), .A_WIDTH(A_WIDTH), .B_WIDTH(B_WIDTH), .Y_WIDTH(A_WIDTH)) u_mul (.A(q), .B(B), .Y(prod));
  $sub #(.A_SIGNED(A_SIGNED), .B_SIGNED(B_SIGNED), .A_WIDTH(A_WIDTH), .B_WIDTH(A_WIDTH), .Y_WIDTH(Y_WIDTH)) u_sub (.A(A), .B(prod), .Y(Y));
endmodule
