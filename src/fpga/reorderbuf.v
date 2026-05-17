`include "constants.vh"
`include "rv32_opcodes.vh"
`default_nettype none
module reorderbuf
  (
   input wire 			  clk,
   input wire 			  reset,
   //Write Signal
   input wire 			  dp1,
   input wire [`RRF_SEL-1:0] 	  dp1_addr,
   input wire [`INSN_LEN-1:0] 	  pc_dp1,
   input wire [`INSN_LEN-1:0] 	  inst_dp1,
   input wire [`REG_SEL-1:0] 	  rs1_dp1,
   input wire [`REG_SEL-1:0] 	  rs2_dp1,
   input wire 			  storebit_dp1,
   input wire 			  dstvalid_dp1,
   input wire [`REG_SEL-1:0] 	  dst_dp1,
   input wire [`GSH_BHR_LEN-1:0]  bhr_dp1,
   input wire 			  isbranch_dp1,
   input wire 			  dp2,
   input wire [`RRF_SEL-1:0] 	  dp2_addr,
   input wire [`INSN_LEN-1:0] 	  pc_dp2,
   input wire [`INSN_LEN-1:0] 	  inst_dp2,
   input wire [`REG_SEL-1:0] 	  rs1_dp2,
   input wire [`REG_SEL-1:0] 	  rs2_dp2,
   input wire 			  storebit_dp2,
   input wire 			  dstvalid_dp2,
   input wire [`REG_SEL-1:0] 	  dst_dp2,
   input wire [`GSH_BHR_LEN-1:0]  bhr_dp2,
   input wire 			  isbranch_dp2,
   input wire 			  exfin_alu1,
   input wire [`RRF_SEL-1:0] 	  exfin_alu1_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_alu1_rs1_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_alu1_rs2_rdata,
   input wire 			  exfin_alu2,
   input wire [`RRF_SEL-1:0] 	  exfin_alu2_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_alu2_rs1_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_alu2_rs2_rdata,
   input wire 			  exfin_mul,
   input wire [`RRF_SEL-1:0] 	  exfin_mul_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_mul_rs1_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_mul_rs2_rdata,
   input wire 			  exfin_ldst,
   input wire [`RRF_SEL-1:0] 	  exfin_ldst_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_ldst_rs1_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_ldst_rs2_rdata,
   input wire [`ADDR_LEN-1:0] 	  exfin_ldst_mem_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_ldst_mem_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_ldst_mem_wdata,
   input wire 			  exfin_branch,
   input wire [`RRF_SEL-1:0] 	  exfin_branch_addr,
   input wire [`DATA_LEN-1:0] 	  exfin_branch_rs1_rdata,
   input wire [`DATA_LEN-1:0] 	  exfin_branch_rs2_rdata,
   input wire 			  exfin_branch_brcond,
   input wire [`ADDR_LEN-1:0] 	  exfin_branch_jmpaddr, 
   input wire [`DATA_LEN-1:0] 	  com1data,
   input wire [`DATA_LEN-1:0] 	  com2data,
  
   output reg [`RRF_SEL-1:0] 	  comptr,
   output wire [`RRF_SEL-1:0] 	  comptr2,
   output wire [1:0] 		  comnum,
   output wire 			  stcommit,
   output wire 			  arfwe1,
   output wire 			  arfwe2,
   output wire [`REG_SEL-1:0] 	  dstarf1,
   output wire [`REG_SEL-1:0] 	  dstarf2,
   output wire [`ADDR_LEN-1:0] 	  pc_combranch,
   output wire [`GSH_BHR_LEN-1:0] bhr_combranch,
   output wire 			  brcond_combranch,
   output wire [`ADDR_LEN-1:0] 	  jmpaddr_combranch,
   output wire 			  combranch,
   output wire [1:0] 		  rvfi_valid,
   output wire [2*`INSN_LEN-1:0]  rvfi_insn,
   output wire [2*`REG_SEL-1:0]   rvfi_rs1_addr,
   output wire [2*`REG_SEL-1:0]   rvfi_rs2_addr,
   output wire [2*`DATA_LEN-1:0]  rvfi_rs1_rdata,
   output wire [2*`DATA_LEN-1:0]  rvfi_rs2_rdata,
   output wire [2*`REG_SEL-1:0]   rvfi_rd_addr,
   output wire [2*`DATA_LEN-1:0]  rvfi_rd_wdata,
   output wire [2*`ADDR_LEN-1:0]  rvfi_pc_rdata,
   output wire [2*`ADDR_LEN-1:0]  rvfi_pc_wdata,
   output wire [2*`ADDR_LEN-1:0]  rvfi_mem_addr,
   output wire [7:0] 		  rvfi_mem_rmask,
   output wire [7:0] 		  rvfi_mem_wmask,
   output wire [2*`DATA_LEN-1:0]  rvfi_mem_rdata,
   output wire [2*`DATA_LEN-1:0]  rvfi_mem_wdata,
   input wire [`RRF_SEL-1:0] 	  dispatchptr,
   input wire [`RRF_SEL:0] 	  rrf_freenum,
   input wire 			  prmiss
   );

   reg [`RRF_NUM-1:0] 		  finish;
   reg [`RRF_NUM-1:0] 		  storebit;
   reg [`RRF_NUM-1:0] 		  dstvalid;
   reg [`RRF_NUM-1:0] 		  brcond;
   reg [`RRF_NUM-1:0] 		  isbranch;
   
   reg [`INSN_LEN-1:0] 		  inst [0:`RRF_NUM-1];
   reg [`ADDR_LEN-1:0] 		  inst_pc [0:`RRF_NUM-1];
   reg [`ADDR_LEN-1:0] 		  jmpaddr [0:`RRF_NUM-1];   
   reg [`ADDR_LEN-1:0] 		  mem_addr [0:`RRF_NUM-1];
   reg [`DATA_LEN-1:0] 		  mem_rdata [0:`RRF_NUM-1];
   reg [`DATA_LEN-1:0] 		  mem_wdata [0:`RRF_NUM-1];
   reg [`DATA_LEN-1:0] 		  rs1_rdata [0:`RRF_NUM-1];
   reg [`DATA_LEN-1:0] 		  rs2_rdata [0:`RRF_NUM-1];
   reg [`REG_SEL-1:0] 		  dst [0:`RRF_NUM-1];
   reg [`REG_SEL-1:0] 		  rs1 [0:`RRF_NUM-1];
   reg [`REG_SEL-1:0] 		  rs2 [0:`RRF_NUM-1];
   reg [`GSH_BHR_LEN-1:0] 	  bhr [0:`RRF_NUM-1];
   
   assign comptr2 = comptr+1;
   
   wire 			  hidp = (comptr > dispatchptr) || (rrf_freenum == 0) ?
				  1'b1 : 1'b0;
   wire 			  com_en1 = ({hidp, dispatchptr} - {1'b0, comptr}) > 0 ? 1'b1 : 1'b0;
   wire 			  com_en2 = ({hidp, dispatchptr} - {1'b0, comptr}) > 1 ? 1'b1 : 1'b0;
   wire 			  commit1 = com_en1 & finish[comptr];
   //   wire commit2 = commit1 & com_en2 & finish[comptr2];

   wire 			  commit2 = 
				  ~(~prmiss & commit1 & isbranch[comptr]) &
				  ~(commit1 & storebit[comptr] & ~prmiss) &
				  commit1 & com_en2 & finish[comptr2];

   assign comnum = {1'b0, commit1} + {1'b0, commit2};
   assign stcommit = (commit1 & storebit[comptr] & ~prmiss) |
		     (commit2 & storebit[comptr2] & ~prmiss);
   assign arfwe1 = ~prmiss & commit1 & dstvalid[comptr];
   assign arfwe2 = ~prmiss & commit2 & dstvalid[comptr2];
   assign dstarf1 = dst[comptr];
   assign dstarf2 = dst[comptr2];
   assign combranch = (~prmiss & commit1 & isbranch[comptr]) |
		      (~prmiss & commit2 & isbranch[comptr2]);
   assign pc_combranch = (~prmiss & commit1 & isbranch[comptr]) ? 
			 inst_pc[comptr] : inst_pc[comptr2];
   assign bhr_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			  bhr[comptr] : bhr[comptr2];
   assign brcond_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			     brcond[comptr] : brcond[comptr2];
   assign jmpaddr_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			      jmpaddr[comptr] : jmpaddr[comptr2];

   wire 			  rvfi_commit1 = ~prmiss & commit1;
   wire 			  rvfi_commit2 = ~prmiss & commit2;

   wire 			  rvfi_load1 = inst[comptr][6:0] == `RV32_LOAD;
   wire 			  rvfi_load2 = inst[comptr2][6:0] == `RV32_LOAD;
   wire 			  rvfi_store1 = inst[comptr][6:0] == `RV32_STORE;
   wire 			  rvfi_store2 = inst[comptr2][6:0] == `RV32_STORE;
   wire [`ADDR_LEN-1:0] 	  rvfi_pc_wdata1 =
				  isbranch[comptr] ?
				  (brcond[comptr] ? jmpaddr[comptr] : inst_pc[comptr] + 4) :
				  inst_pc[comptr] + 4;
   wire [`ADDR_LEN-1:0] 	  rvfi_pc_wdata2 =
				  isbranch[comptr2] ?
				  (brcond[comptr2] ? jmpaddr[comptr2] : inst_pc[comptr2] + 4) :
				  inst_pc[comptr2] + 4;
   wire [`REG_SEL-1:0] 	  rvfi_rd_addr1 = dstvalid[comptr] ? dst[comptr] : 0;
   wire [`REG_SEL-1:0] 	  rvfi_rd_addr2 = dstvalid[comptr2] ? dst[comptr2] : 0;

   assign rvfi_valid = {rvfi_commit2, rvfi_commit1};
   assign rvfi_insn = {inst[comptr2], inst[comptr]};
   assign rvfi_rs1_addr = {rs1[comptr2], rs1[comptr]};
   assign rvfi_rs2_addr = {rs2[comptr2], rs2[comptr]};
   assign rvfi_rs1_rdata = {
			    rs1[comptr2] == 0 ? `DATA_LEN'b0 : rs1_rdata[comptr2],
			    rs1[comptr] == 0 ? `DATA_LEN'b0 : rs1_rdata[comptr]
			    };
   assign rvfi_rs2_rdata = {
			    rs2[comptr2] == 0 ? `DATA_LEN'b0 : rs2_rdata[comptr2],
			    rs2[comptr] == 0 ? `DATA_LEN'b0 : rs2_rdata[comptr]
			    };
   assign rvfi_rd_addr = {rvfi_rd_addr2, rvfi_rd_addr1};
   assign rvfi_rd_wdata = {
			   rvfi_rd_addr2 == 0 ? `DATA_LEN'b0 : com2data,
			   rvfi_rd_addr1 == 0 ? `DATA_LEN'b0 : com1data
			   };
   assign rvfi_pc_rdata = {inst_pc[comptr2], inst_pc[comptr]};
   assign rvfi_pc_wdata = {rvfi_pc_wdata2, rvfi_pc_wdata1};
   assign rvfi_mem_addr = {mem_addr[comptr2], mem_addr[comptr]};
   assign rvfi_mem_rmask = {rvfi_load2 ? 4'hf : 4'h0, rvfi_load1 ? 4'hf : 4'h0};
   assign rvfi_mem_wmask = {rvfi_store2 ? 4'hf : 4'h0, rvfi_store1 ? 4'hf : 4'h0};
   assign rvfi_mem_rdata = {rvfi_load2 ? mem_rdata[comptr2] : `DATA_LEN'b0,
			    rvfi_load1 ? mem_rdata[comptr] : `DATA_LEN'b0};
   assign rvfi_mem_wdata = {rvfi_store2 ? mem_wdata[comptr2] : `DATA_LEN'b0,
			    rvfi_store1 ? mem_wdata[comptr] : `DATA_LEN'b0};
   

   always @ (posedge clk) begin
      if (reset) begin
	 comptr <= 0;
      end else if (~prmiss) begin
	 comptr <= comptr + commit1 + commit2;
      end
   end
   
   always @ (posedge clk) begin
      if (reset) begin
	 finish <= 0;
	 brcond <= 0;
      end else begin
	 if (dp1)
	   finish[dp1_addr] <= 1'b0;
	 if (dp2)
	   finish[dp2_addr] <= 1'b0;
	 if (exfin_alu1)
	   finish[exfin_alu1_addr] <= 1'b1;
	 if (exfin_alu2)
	   finish[exfin_alu2_addr] <= 1'b1;
	 if (exfin_mul)
	   finish[exfin_mul_addr] <= 1'b1;
	 if (exfin_ldst)
	   finish[exfin_ldst_addr] <= 1'b1;
	 if (exfin_branch) begin
	    finish[exfin_branch_addr] <= 1'b1;
	    brcond[exfin_branch_addr] <= exfin_branch_brcond;
	    jmpaddr[exfin_branch_addr] <= exfin_branch_jmpaddr;
	 end
      end
   end // always @ (posedge clk)

   always @ (posedge clk) begin
      if (exfin_alu1) begin
	 rs1_rdata[exfin_alu1_addr] <= exfin_alu1_rs1_rdata;
	 rs2_rdata[exfin_alu1_addr] <= exfin_alu1_rs2_rdata;
      end
      if (exfin_alu2) begin
	 rs1_rdata[exfin_alu2_addr] <= exfin_alu2_rs1_rdata;
	 rs2_rdata[exfin_alu2_addr] <= exfin_alu2_rs2_rdata;
      end
      if (exfin_mul) begin
	 rs1_rdata[exfin_mul_addr] <= exfin_mul_rs1_rdata;
	 rs2_rdata[exfin_mul_addr] <= exfin_mul_rs2_rdata;
      end
      if (exfin_ldst) begin
	 rs1_rdata[exfin_ldst_addr] <= exfin_ldst_rs1_rdata;
	 rs2_rdata[exfin_ldst_addr] <= exfin_ldst_rs2_rdata;
	 mem_addr[exfin_ldst_addr] <= exfin_ldst_mem_addr;
	 mem_rdata[exfin_ldst_addr] <= exfin_ldst_mem_rdata;
	 mem_wdata[exfin_ldst_addr] <= exfin_ldst_mem_wdata;
      end
      if (exfin_branch) begin
	 rs1_rdata[exfin_branch_addr] <= exfin_branch_rs1_rdata;
	 rs2_rdata[exfin_branch_addr] <= exfin_branch_rs2_rdata;
      end
   end

   always @ (posedge clk) begin
      if (dp1) begin
	 inst[dp1_addr] <= inst_dp1;
	 isbranch[dp1_addr] <= isbranch_dp1;
	 storebit[dp1_addr] <= storebit_dp1;
	 dstvalid[dp1_addr] <= dstvalid_dp1;
	 dst[dp1_addr] <= dst_dp1;
	 rs1[dp1_addr] <= rs1_dp1;
	 rs2[dp1_addr] <= rs2_dp1;
	 bhr[dp1_addr] <= bhr_dp1;
	 inst_pc[dp1_addr] <= pc_dp1;
	 mem_addr[dp1_addr] <= 0;
	 mem_rdata[dp1_addr] <= 0;
	 mem_wdata[dp1_addr] <= 0;
      end
      if (dp2) begin
	 inst[dp2_addr] <= inst_dp2;
	 isbranch[dp2_addr] <= isbranch_dp2;
	 storebit[dp2_addr] <= storebit_dp2;
	 dstvalid[dp2_addr] <= dstvalid_dp2;
	 dst[dp2_addr] <= dst_dp2;
	 rs1[dp2_addr] <= rs1_dp2;
	 rs2[dp2_addr] <= rs2_dp2;
	 bhr[dp2_addr] <= bhr_dp2;
	 inst_pc[dp2_addr] <= pc_dp2;
	 mem_addr[dp2_addr] <= 0;
	 mem_rdata[dp2_addr] <= 0;
	 mem_wdata[dp2_addr] <= 0;
      end
   end
endmodule // reorderbuf
`default_nettype wire
