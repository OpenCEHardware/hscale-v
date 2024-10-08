module hsv_core_branch_jump
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic         valid_i,
    input branch_data_t in_branch_data,
    input logic         in_taken,
    input word          in_target,

    output logic         valid_o,
    output commit_data_t out
);

  word final_pc;
  logic alignment_exception, mispredict;
  commit_action_t action;

  assign final_pc = in_taken ? in_target : in_branch_data.common.pc_increment;
  assign mispredict = final_pc != in_branch_data.predicted;

  // Trap if target address is not aligned to a 4-byte boundary
  assign alignment_exception = in_taken & (in_target[$bits(word)-$bits(pc_ptr)-1:0] != '0);

  always_comb
    if (alignment_exception) action = COMMIT_EXCEPTION;
    else if (mispredict) action = COMMIT_JUMP;
    else action = COMMIT_NEXT;

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      valid_o <= valid_i;

      out.action <= action;
      out.common <= in_branch_data.common;
      out.result <= in_branch_data.common.pc_increment;
      out.next_pc <= final_pc;
      out.writeback <= in_branch_data.link;
      out.exception_cause <= EXC_INSTRUCTION_ADDRESS_MISALIGNED;
      out.exception_value <= in_target;
    end

    if (flush_req) valid_o <= 0;
  end

endmodule
