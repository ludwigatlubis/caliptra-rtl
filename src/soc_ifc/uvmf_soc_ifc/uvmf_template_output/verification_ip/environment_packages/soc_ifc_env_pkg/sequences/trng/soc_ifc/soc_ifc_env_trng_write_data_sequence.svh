//----------------------------------------------------------------------
// Created with uvmf_gen version 2022.3
//----------------------------------------------------------------------
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// DESCRIPTION: TRNG data written by external source in response to 
//              DATA_REQ via CPTRA_TRNG_STATUS register. 
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class soc_ifc_env_trng_write_data_sequence extends soc_ifc_env_sequence_base #(.CONFIG_T(soc_ifc_env_configuration_t));

  `uvm_object_utils( soc_ifc_env_trng_write_data_sequence )

  rand bit trng_write_done;
  rand bit [3:0] trng_num_dwords;

  bit trng_data_req;

  extern virtual task soc_ifc_env_trng_poll_data_req();
  extern virtual task soc_ifc_env_trng_check_data_req(output bit data_req);
  extern virtual task soc_ifc_env_trng_write_data();
  extern virtual task soc_ifc_env_trng_write_done();

  // Constrain trng_write_done to be 1
  constraint trng_write_done_1 { trng_write_done == 1; }  

  // Constrain trng_num_dwords to be 12
  constraint  trng_num_dwords_12 { trng_num_dwords == 12; }

  function new(string name = "" );
    super.new(name);
  endfunction

  virtual task pre_body();
    super.pre_body();
    reg_model = configuration.soc_ifc_rm;

    if (soc_ifc_status_agent_rsp_seq == null)
        `uvm_fatal("TRNG_REQ_SEQ", "TRNG REQ Sequence expected a handle to the soc_ifc status agent responder sequence (from bench-level sequence) but got null!")

  endtask

  virtual task body();

    `uvm_info("TRNG_REQ_SEQ", $sformatf("Responding to TRNG_DATA_REQ with %0d dwords", trng_num_dwords), UVM_DEBUG)
    if (this.trng_data_req == 1'b0) 
      soc_ifc_env_trng_poll_data_req();
    if (this.trng_data_req) begin
      soc_ifc_env_trng_write_data();
      soc_ifc_env_trng_write_done();
    end

  endtask

endclass

task soc_ifc_env_trng_write_data_sequence::soc_ifc_env_trng_poll_data_req();
  bit data_req;

  soc_ifc_env_trng_check_data_req(data_req);
  while (data_req == 1'b0) begin
    configuration.soc_ifc_ctrl_agent_config.wait_for_num_clocks(200);
    soc_ifc_env_trng_check_data_req(data_req);
  end
  this.trng_data_req = data_req;
endtask

task soc_ifc_env_trng_write_data_sequence::soc_ifc_env_trng_check_data_req(output bit data_req);
  uvm_status_e reg_sts;
  uvm_reg_data_t reg_data;
  reg_model.soc_ifc_reg_rm.CPTRA_TRNG_STATUS.read(reg_sts, reg_data, UVM_FRONTDOOR, reg_model.soc_ifc_APB_map, this);
  if (reg_sts != UVM_IS_OK) begin
    `uvm_error("TRNG_REQ_SEQ", "Register access failed (CPTRA_TRNG_STATUS)")
  end
  else begin
    data_req = reg_data >> reg_model.soc_ifc_reg_rm.CPTRA_TRNG_STATUS.DATA_REQ.get_lsb_pos();
  end
endtask

task soc_ifc_env_trng_write_data_sequence::soc_ifc_env_trng_write_data();
  int ii;
  uvm_status_e reg_sts;
  uvm_reg_data_t data;
  for (ii = 0; ii < this.trng_num_dwords; ii++) begin
    if (!std::randomize(data)) `uvm_error("TRNG_REQ_SEQ", "Failed to randomize data")
    `uvm_info("TRNG_REQ_SEQ", $sformatf("Sending TRNG_DATA[%0d]: 0x%0x", ii, data), UVM_DEBUG)
    reg_model.soc_ifc_reg_rm.CPTRA_TRNG_DATA[ii].write(reg_sts, uvm_reg_data_t'(data), UVM_FRONTDOOR, reg_model.soc_ifc_APB_map, this);
    if (reg_sts != UVM_IS_OK) 
      `uvm_error("TRNG_REQ_SEQ", "Register access failed (TRNG_DATA)")
  end
endtask

task soc_ifc_env_trng_write_data_sequence::soc_ifc_env_trng_write_done();
  uvm_status_e reg_sts;
  `uvm_info("TRNG_REQ_SEQ", "Sending TRNG_DONE", UVM_DEBUG)
  reg_model.soc_ifc_reg_rm.CPTRA_TRNG_STATUS.DATA_WR_DONE.write(reg_sts, uvm_reg_data_t'(trng_write_done), UVM_FRONTDOOR, reg_model.soc_ifc_APB_map, this);
  if (reg_sts != UVM_IS_OK) 
    `uvm_error("TRNG_REQ_SEQ", "Register access failed (TRNG_DONE)")
endtask


