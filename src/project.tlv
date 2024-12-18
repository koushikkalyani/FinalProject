\m5_TLV_version 1d: tl-x.org
\m5
   /**
   This template is for developing Tiny Tapeout designs using Makerchip.
   Verilog, SystemVerilog, and/or TL-Verilog can be used.
   Use of Tiny Tapeout Demo Boards (as virtualized in the VIZ tab) is supported.
   See the corresponding Git repository for build instructions.
   **/

   use(m5-1.0)  // See M5 docs in Makerchip IDE Learn menu.

   // ---SETTINGS---
   var(my_design, tt_um_example)  /// Change tt_um_example to tt_um_<your-github-username>_<name-of-your-project>. (See README.md.)
   var(debounce_inputs, 0)
                     /// Legal values:
                     ///   1: Provide synchronization and debouncing on all input signals.
                     ///   0: Don't provide synchronization and debouncing.
                     ///   m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   // --------------

   // If debouncing, your top module is wrapped within a debouncing module, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))
\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/5744600215af09224b7235479be84c30c6e50cb7/tlv_lib/tiny_tapeout_lib.tlv'])

\TLV my_design()

   // ============================================
   // If you are using TL-Verilog for your design,
   // your TL-Verilog logic goes here.
   // Optionally, provide \viz_js here (for TL-Verilog or Verilog logic).
   // Tiny Tapeout inputs can be referenced as, e.g. *ui_in.
   // (Connect Tiny Tapeout outputs at the end of this template.)
   // ============================================

   // ...
   |ma
      @0
         $reset = *reset;
         $enter = *ui_in[7];
         $num[3:0] = *ui_in[3:0];
         $valid = $enter && ! >>1$enter;
         $sample1[3:0] =  $num ;          // Current input sample
         $sample2[3:0] = >>1$sample1;     // Previous sample
         $sample3[3:0] = >>1$sample2;     // Two cycles back
         $sum[5:0] = ({2'b0, $sample1} + {2'b0, $sample2} + {2'b0, $sample3});  // 3 samples sum
         $avg_calc[5:0] = $sum / 3;
         $avg[3:0] = $valid ? $avg_calc[3:0] : >>1$avg ;// Divide by 3 
      @1
         $out[3:0] = $reset ? 4'b0 :
                  ! $valid ? >>1$out :
                    $avg[3:0];
         $digit[3:0] = $out[3:0];
      @2 
         *uo_out =
            $digit == 4'h0 ? 8'b00111111 :
            $digit == 4'h1 ? 8'b00000110 :
            $digit == 4'h2 ? 8'b01011011 :
            $digit == 4'h3 ? 8'b01001111 :
            $digit == 4'h4 ? 8'b01100110 :
            $digit == 4'h5 ? 8'b01101101 :
            $digit == 4'h6 ? 8'b01111101 :
            $digit == 4'h7 ? 8'b00000111 :
            $digit == 4'h8 ? 8'b01111111 :
            $digit == 4'h9 ? 8'b01101111 :
            $digit == 4'hA ? 8'b01110111 :
            $digit == 4'hB ? 8'b01111100 :
            $digit == 4'hC ? 8'b00111001 :
            $digit == 4'hD ? 8'b01011110 :
            $digit == 4'hE ? 8'b01111001 :
                             8'b01110001;
\SV


// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uio_in, uo_out, uio_out, uio_oe;
   logic [31:0] r;
   always @(negedge clk) r = m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   assign uio_in = r[15:8];
   logic ena = 1'b0;
   logic rst_n = ! reset;


   /*
   // Or, to provide specific inputs at specific times...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);

   assign passed = cyc_cnt > 100;
   assign failed = 1'b0;
endmodule

// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
// The above macro expands to multiple lines. We enter a new \SV block to reset line tracking.
\SV


// The Tiny Tapeout module.
module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

   wire reset = ! rst_n;

\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()

   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (bottom-to-top).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV_plus

   // =========================================
   // If you are using (System)Verilog for your design,
   // your Verilog logic goes here.
   // =========================================

   // ...


   // Connect Tiny Tapeout outputs.
   // Note that my_design will be under /fpga_pins/fpga.
   // Example *uo_out = /fpga_pins/fpga|my_pipe>>3$uo_out;
   assign *uo_out = 8'b0;
   assign *uio_out = 8'b0;
   assign *uio_oe = 8'b0;

endmodule
