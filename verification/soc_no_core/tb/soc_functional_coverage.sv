//JEEVA SOC FUNCTIONAL COVERAGE 
module soc_functional_coverage;
  typedef enum logic [2:0] {
    MAP_BOOTROM=3'd0, MAP_IMEM=3'd1, MAP_DMEM=3'd2,
    MAP_CLINT=3'd3, MAP_DEBUG=3'd4, MAP_APB=3'd5, MAP_ERROR=3'd6
  } map_region_e;
  typedef enum logic [3:0] {
    IRQ_UART=4'd1, IRQ_I2C=4'd2, IRQ_GPIO=4'd3,
    IRQ_TIMER0_OVF=4'd4, IRQ_TIMER0_CMP=4'd5,
    IRQ_TIMER1_OVF=4'd6, IRQ_TIMER1_CMP=4'd7,
    IRQ_SPI_TXRX=4'd8, IRQ_SPI_EOT=4'd9
  } irq_source_e;
  // These are stages within one boot flow, not independently selectable boot modes.
  typedef enum logic [1:0] {
    BOOT_ROM_WFI=2'd0, BOOT_APP_RUN=2'd1, BOOT_APP_WFI=2'd2
  } boot_mode_e;
  typedef enum logic [2:0] {
    REG_READ=3'd0, REG_WRITE=3'd1, REG_CLAIM=3'd2, REG_COMPLETE=3'd3
  } reg_access_e;
  typedef enum logic [2:0] {
    PERIPH_UART=3'd0, PERIPH_I2C=3'd1, PERIPH_SPI=3'd2,
    PERIPH_GPIO=3'd3, PERIPH_TIMER=3'd4, PERIPH_PLIC=3'd5
  } peripheral_e;

  localparam int REG_SLOTS_PER_PERIPH = 28; // offsets 0x00..0x6C, word aligned
  localparam int REGISTER_ID_MAX = 6*REG_SLOTS_PER_PERIPH-1;
  bit fcov_ready = 1'b0;

  int unsigned map_hits[0:6];
  int unsigned irq_hits[1:9];
  int unsigned boot_hits[0:2];
  int unsigned reg_read_hits[0:REGISTER_ID_MAX];
  int unsigned reg_write_hits[0:REGISTER_ID_MAX];
  int unsigned reg_claim_hits[0:REGISTER_ID_MAX];
  int unsigned reg_complete_hits[0:REGISTER_ID_MAX];
  int unsigned enable_mode_hits[0:5][0:1][0:3];

  function automatic string peripheral_name(input peripheral_e p);
    case (p)
      PERIPH_UART: return "UART";
      PERIPH_I2C:  return "I2C";
      PERIPH_SPI:  return "SPI";
      PERIPH_GPIO: return "GPIO";
      PERIPH_TIMER:return "TIMER";
      PERIPH_PLIC: return "PLIC";
      default:     return "UNKNOWN";
    endcase
  endfunction

  function automatic logic [31:0] peripheral_base(input peripheral_e p);
    case (p)
      PERIPH_UART: return 32'h4000_0000;
      PERIPH_I2C:  return 32'h4000_1000;
      PERIPH_SPI:  return 32'h4000_2000;
      PERIPH_GPIO: return 32'h4000_3000;
      PERIPH_TIMER:return 32'h4000_4000;
      PERIPH_PLIC: return 32'h4000_5000;
      default:     return 32'h0000_0000;
    endcase
  endfunction

  // Empty string means that the supplied RTL/TB excerpts do not establish
  // a named register at this offset; such holes are not counted as signoff bins.
  function automatic string register_name(input peripheral_e p, input logic [11:0] off);
    case (p)
      PERIPH_UART: case (off)
        12'h000: return "RBR/THR/DLL (DLAB alias)";
        12'h004: return "IER/DLM (DLAB alias)";
        12'h008: return "IIR/FCR (read/write alias)";
        12'h00C: return "LCR";
        12'h014: return "LSR";
        default: return "";
      endcase
      PERIPH_I2C: case (off)
        12'h000: return "PRESCALE";
        12'h004: return "CTRL";
        12'h008: return "RXR (read-only)";
        12'h00C: return "STATUS (TIP/RXACK/BUSY/AL/IRQ)";
        12'h010: return "TXR (write register)";
        12'h014: return "CMD (write register/readback)";
        default: return "";
      endcase
      PERIPH_SPI: case (off)
        12'h000: return "STATUS/START";
        12'h004: return "CLKDIV";
        12'h008: return "SPICMD";
        12'h00C: return "SPIADR";
        12'h010: return "SPILEN";
        12'h014: return "SPIDUM";
        12'h018: return "TXFIFO";
        12'h020: return "RXFIFO";
        12'h024: return "INTCFG";
        12'h028: return "INTSTA";
        default: return "";
      endcase
      PERIPH_GPIO: case (off)
        12'h000: return "PADDIR_00_31";
        12'h004: return "GPIOEN_00_31";
        12'h008: return "PADIN_00_31";
        12'h00C: return "PADOUT_00_31";
        12'h010: return "PADOUTSET_00_31";
        12'h014: return "PADOUTCLR_00_31";
        12'h018: return "INTEN_00_31";
        12'h01C: return "INTTYPE_00_15";
        12'h020: return "INTTYPE_16_31";
        12'h024: return "INTSTATUS_00_31";
        12'h028: return "PADCFG_00_07";
        12'h02C: return "PADCFG_08_15";
        12'h030: return "PADCFG_16_23";
        12'h034: return "PADCFG_24_31";
  
        default: return "";
      endcase
      PERIPH_TIMER: case (off)
        12'h000: return "TIMER0_COUNT";
        12'h004: return "TIMER0_CTRL";
        12'h008: return "TIMER0_CMP";
        12'h010: return "TIMER1_COUNT";
        12'h014: return "TIMER1_CTRL";
        12'h018: return "TIMER1_CMP";
        default: return "";
      endcase
      PERIPH_PLIC: case (off)
        // Actual plic_dynamic_registers map for SOURCES=64, TARGETS=4,
        // PRIORITIES=8, HAS_CONFIG_REG=1, HAS_THRESHOLD=1.
        12'h000: return "CONFIG0";
        12'h004: return "CONFIG1";
        12'h008: return "EL0";
        12'h00C: return "EL1";
        12'h010: return "PRIORITY0_P0_P7";
        12'h014: return "PRIORITY1_P8_P15";
        12'h018: return "PRIORITY2_P16_P23";
        12'h01C: return "PRIORITY3_P24_P31";
        12'h020: return "PRIORITY4_P32_P39";
        12'h024: return "PRIORITY5_P40_P47";
        12'h028: return "PRIORITY6_P48_P55";
        12'h02C: return "PRIORITY7_P56_P63";
        12'h030: return "IE0";
        12'h034: return "IE1";
        12'h038: return "IE2";
        12'h03C: return "IE3";
        12'h040: return "IE4";
        12'h044: return "IE5";
        12'h048: return "IE6";
        12'h04C: return "IE7";
        12'h050: return "THRESHOLD0";
        12'h054: return "THRESHOLD1";
        12'h058: return "THRESHOLD2";
        12'h05C: return "THRESHOLD3";
        12'h060: return "TARGET0_CLAIM_COMPLETE";
        12'h064: return "TARGET1_CLAIM_COMPLETE";
        12'h068: return "TARGET2_CLAIM_COMPLETE";
        12'h06C: return "TARGET3_CLAIM_COMPLETE";
        default: return "";
      endcase
      default: return "";
    endcase
  endfunction

  function automatic int unsigned register_key(input peripheral_e p, input logic [11:0] byte_offset);
    return (int'(p) * REG_SLOTS_PER_PERIPH) + (byte_offset >> 2);
  endfunction


  // Legal APB access directions for each implemented register.
  // Aliased registers are represented by the union of their read/write views.
  function automatic bit legal_read(
      input peripheral_e p, input logic [11:0] off);
    case (p)
      PERIPH_UART: begin
        case (off)
          12'h000, 12'h004, 12'h008,
          12'h00C, 12'h014: return 1'b1;
          default: return 1'b0;
        endcase
      end

      PERIPH_I2C:
        case (off)
          // RXR is a read-only view of the byte controller receive data.
          12'h000, 12'h004, 12'h008, 12'h00C, 12'h010, 12'h014: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_SPI:
        case (off)
          12'h000, 12'h004, 12'h008, 12'h00C, 12'h010,
          12'h014, 12'h020, 12'h024, 12'h028: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_GPIO:
        case (off)
          12'h000, 12'h004, 12'h008, 12'h00C,
          12'h018, 12'h01C, 12'h020, 12'h024,
          12'h028, 12'h02C, 12'h030, 12'h034: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_TIMER:
        case (off)
          12'h000, 12'h004, 12'h008,
          12'h010, 12'h014, 12'h018: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_PLIC: begin
        // CONFIG, EL, PRIORITY, IE and THRESHOLD are readable.
        // ID offsets 0x60..0x6C are claim operations, not ordinary reads.
        if (off <= 12'h05C && off[1:0] == 2'b00)
          return 1'b1;
        return 1'b0;
      end

      default: return 1'b0;
    endcase
  endfunction

  function automatic bit legal_write(
      input peripheral_e p, input logic [11:0] off);
    case (p)
      PERIPH_UART: begin
        case (off)
          12'h000, 12'h004, 12'h008,
          12'h00C: return 1'b1;
          default: return 1'b0;
        endcase
      end

      PERIPH_I2C:
        case (off)
          12'h000, 12'h004, 12'h010, 12'h014: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_SPI:
        case (off)
          12'h000, 12'h004, 12'h008, 12'h00C, 12'h010,
          12'h014, 12'h018, 12'h024: return 1'b1;
          // RXFIFO is read-only.
          default: return 1'b0;
        endcase

      PERIPH_GPIO:
        case (off)
          12'h000, 12'h004, 12'h00C, 12'h010,
          12'h014, 12'h018, 12'h01C, 12'h020,
          12'h028, 12'h02C, 12'h030,
          12'h034: return 1'b1;
          // PADIN is read-only; PADOUTSET/CLR are write-only.
          default: return 1'b0;
        endcase

      PERIPH_TIMER:
        case (off)
          12'h000, 12'h004, 12'h008,
          12'h010, 12'h014, 12'h018: return 1'b1;
          default: return 1'b0;
        endcase

      PERIPH_PLIC: begin
        // CONFIG, EL, PRIORITY, IE and THRESHOLD are writable.
        // ID offsets 0x60..0x6C generate completion strobes, not writes.
        if (off <= 12'h05C && off[1:0] == 2'b00)
          return 1'b1;
        return 1'b0;
      end

      default: return 1'b0;
    endcase
  endfunction

  function automatic bit legal_claim(input peripheral_e p, input logic [11:0] off);
    return (p == PERIPH_PLIC) &&
           (off >= 12'h060) && (off <= 12'h06C) &&
           (off[1:0] == 2'b00);
  endfunction

  function automatic bit legal_complete(input peripheral_e p, input logic [11:0] off);
    return (p == PERIPH_PLIC) &&
           (off >= 12'h060) && (off <= 12'h06C) &&
           (off[1:0] == 2'b00);
  endfunction

  function automatic bit legal_register_access(
      input peripheral_e p, input logic [11:0] off,
      input reg_access_e access_kind);
    case (access_kind)
      REG_READ:     return legal_read(p, off);
      REG_WRITE:    return legal_write(p, off);
      REG_CLAIM:    return legal_claim(p, off);
      REG_COMPLETE: return legal_complete(p, off);
      default:      return 1'b0;
    endcase
  endfunction

  covergroup address_map_cg with function sample(map_region_e region);
    option.per_instance=1;
    cp_region: coverpoint region {
      bins bootrom={MAP_BOOTROM}; bins imem={MAP_IMEM}; bins dmem={MAP_DMEM};
      bins clint={MAP_CLINT}; bins debug={MAP_DEBUG}; bins apb={MAP_APB}; bins error={MAP_ERROR};
    }
  endgroup
  covergroup interrupt_source_cg with function sample(irq_source_e source);
    option.per_instance=1;
    cp_source: coverpoint source {
      bins uart={IRQ_UART}; bins i2c={IRQ_I2C}; bins gpio={IRQ_GPIO};
      bins timer0_ovf={IRQ_TIMER0_OVF}; bins timer0_cmp={IRQ_TIMER0_CMP};
      bins timer1_ovf={IRQ_TIMER1_OVF}; bins timer1_cmp={IRQ_TIMER1_CMP};
      bins spi_txrx={IRQ_SPI_TXRX}; bins spi_eot={IRQ_SPI_EOT};
    }
  endgroup
  covergroup boot_mode_cg with function sample(boot_mode_e mode);
    option.per_instance=1;
    cp_boot_mode: coverpoint mode {
      bins bootrom_wfi={BOOT_ROM_WFI}; bins app_running={BOOT_APP_RUN}; bins app_wfi={BOOT_APP_WFI};
    }
  endgroup
  covergroup register_access_cg with function sample(int unsigned reg_id, reg_access_e access_kind);
    option.per_instance=1;
    cp_register: coverpoint reg_id {
      bins uart={[0:27]}; bins i2c={[28:55]}; bins spi={[56:83]};
      bins gpio={[84:97]}; bins timer={[112:139]}; bins plic={[140:167]};
      illegal_bins invalid=default;
    }
    cp_access: coverpoint access_kind {
      bins read={REG_READ}; bins write={REG_WRITE}; bins claim={REG_CLAIM}; bins complete={REG_COMPLETE};
    }
    cx_reg_access: cross cp_register, cp_access {
      ignore_bins non_plic_claims = !binsof(cp_register.plic) &&
        binsof(cp_access) intersect {REG_CLAIM,REG_COMPLETE};
    }
  endgroup
  covergroup enable_mode_cg with function sample(peripheral_e peripheral, bit enabled, logic [1:0] mode);
    option.per_instance=1;
    cp_peripheral: coverpoint peripheral {
      bins uart={PERIPH_UART}; bins i2c={PERIPH_I2C}; bins spi={PERIPH_SPI};
      bins gpio={PERIPH_GPIO}; bins timer={PERIPH_TIMER}; bins plic={PERIPH_PLIC};
    }
    cp_enable: coverpoint enabled { bins disabled={0}; bins enabled={1}; }
    cp_mode: coverpoint mode { bins mode_00={0}; bins mode_01={1}; bins mode_10={2}; bins mode_11={3}; }
  endgroup

  address_map_cg address_map_cov;
  interrupt_source_cg interrupt_source_cov;
  boot_mode_cg boot_mode_cov;
  register_access_cg register_access_cov;
  enable_mode_cg enable_mode_cov;

  initial begin
    address_map_cov=new(); interrupt_source_cov=new(); boot_mode_cov=new();
    register_access_cov=new(); enable_mode_cov=new();
    foreach(map_hits[i]) map_hits[i]=0;
    foreach(irq_hits[i]) irq_hits[i]=0;
    foreach(boot_hits[i]) boot_hits[i]=0;
    foreach(reg_read_hits[i]) begin
      reg_read_hits[i]=0; reg_write_hits[i]=0; reg_claim_hits[i]=0; reg_complete_hits[i]=0;
    end
    foreach(enable_mode_hits[i,j,k]) enable_mode_hits[i][j][k]=0;
    fcov_ready=1'b1;
  end

  task automatic sample_address_map(input map_region_e region);
    address_map_cov.sample(region); map_hits[region]++;
  endtask
  task automatic sample_interrupt(input irq_source_e source);
    interrupt_source_cov.sample(source); irq_hits[source]++;
  endtask
  task automatic sample_boot_mode(input boot_mode_e mode);
    boot_mode_cov.sample(mode); boot_hits[mode]++;
  endtask
  task automatic sample_register_access(input peripheral_e peripheral,
      input logic [11:0] byte_offset, input reg_access_e access_kind);
    int unsigned key;
    if (byte_offset[1:0] != 2'b00 || byte_offset > 12'h06C)
      $fatal(1,"[FCOV] Invalid %s register byte offset 0x%03h",peripheral_name(peripheral),byte_offset);

    // This SoC implements GPIO[31:0] only: valid GPIO offsets are 0x00..0x34.
    if (peripheral == PERIPH_GPIO && byte_offset > 12'h034)
      $fatal(1,
        "[FCOV] Invalid GPIO access: offset 0x%03h is outside GPIO[31:0]",
        byte_offset);

    if (!legal_register_access(peripheral, byte_offset, access_kind))
      $fatal(1,
        "[FCOV] Illegal %s access kind %0d at offset 0x%03h",
        peripheral_name(peripheral), access_kind, byte_offset);

    key=register_key(peripheral,byte_offset);
    register_access_cov.sample(key,access_kind);
    case(access_kind)
      REG_READ: reg_read_hits[key]++;
      REG_WRITE: reg_write_hits[key]++;
      REG_CLAIM: reg_claim_hits[key]++;
      REG_COMPLETE: reg_complete_hits[key]++;
      default: $fatal(1,"[FCOV] Invalid register access kind");
    endcase
  endtask
  task automatic sample_enable_mode(input peripheral_e peripheral,input bit enabled,input logic [1:0] mode);
    enable_mode_cov.sample(peripheral,enabled,mode); enable_mode_hits[peripheral][enabled][mode]++;
  endtask

  task automatic report_coverage;
    int unsigned missing_map, missing_irq, missing_boot;
    int unsigned missing_reg_read, missing_reg_write;
    int unsigned missing_claim, missing_complete;
    int unsigned p, s, key;
    logic [11:0] off;
    string nm;
    peripheral_e pe;
    begin
      missing_map=0; missing_irq=0; missing_boot=0;
      missing_reg_read=0; missing_reg_write=0;
      missing_claim=0; missing_complete=0;

      $display("\n================ FUNCTIONAL COVERAGE ================");
      $display("[FCOV] Address-map regions:");
      for(int i=0;i<=6;i++) begin
        $display("  map[%0d] hits=%0d",i,map_hits[i]);
        if(map_hits[i]==0) missing_map++;
      end

      $display("[FCOV] Implemented PLIC interrupt sources:");
      for(int i=1;i<=9;i++) begin
        $display("  source[%0d] hits=%0d",i,irq_hits[i]);
        if(irq_hits[i]==0) missing_irq++;
      end

      $display("[FCOV] Boot-flow stages:");
      for(int i=0;i<=2;i++) begin
        $display("  boot_stage[%0d] hits=%0d",i,boot_hits[i]);
        if(boot_hits[i]==0) missing_boot++;
      end

      $display("\n[FCOV] Named register access coverage (absolute APB address shown):");
      for(p=0;p<6;p++) begin
        pe=peripheral_e'(p);
        $display("  -- %s --",peripheral_name(pe));
        for(s=0;s<REG_SLOTS_PER_PERIPH;s++) begin
          off=s*4;
          nm=register_name(pe,off);
          if(nm!="") begin
            key=p*REG_SLOTS_PER_PERIPH+s;
            $display("  %-25s addr=0x%08h R=%0d W=%0d CLAIM=%0d COMPLETE=%0d",
              nm,peripheral_base(pe)+off,reg_read_hits[key],reg_write_hits[key],
              reg_claim_hits[key],reg_complete_hits[key]);

            if(legal_read(pe,off) && reg_read_hits[key]==0)
              missing_reg_read++;
            if(legal_write(pe,off) && reg_write_hits[key]==0)
              missing_reg_write++;
            if(legal_claim(pe,off) && reg_claim_hits[key]==0)
              missing_claim++;
            if(legal_complete(pe,off) && reg_complete_hits[key]==0)
              missing_complete++;
          end
        end
      end

      $display("\n[FCOV] Unhit legal access bins: READ=%0d WRITE=%0d CLAIM=%0d COMPLETE=%0d",
        missing_reg_read,missing_reg_write,missing_claim,missing_complete);
$display("\n[FCOV] Enable/mode individual combinations:");

for (int p = 0; p < 6; p++) begin
    for (int e = 0; e < 2; e++) begin
        for (int m = 0; m < 4; m++) begin

            if (enable_mode_hits[p][e][m] == 0) begin
                $display(
                    "  NOT HIT: Peripheral=%s Enable=%0d Mode=%02b",
                    peripheral_name(peripheral_e'(p)),
                    e,
                    m
                );
            end

        end
    end
end
      for(p=0;p<6;p++) begin
        pe=peripheral_e'(p);
        for(s=0;s<REG_SLOTS_PER_PERIPH;s++) begin
          off=s*4;
          nm=register_name(pe,off);
          key=p*REG_SLOTS_PER_PERIPH+s;
          if(nm!="") begin
            if(legal_read(pe,off) && reg_read_hits[key]==0)
              $display("  READ not hit: %-25s @ 0x%08h",nm,peripheral_base(pe)+off);
            if(legal_write(pe,off) && reg_write_hits[key]==0)
              $display("  WRITE not hit: %-24s @ 0x%08h",nm,peripheral_base(pe)+off);
            if(legal_claim(pe,off) && reg_claim_hits[key]==0)
              $display("  CLAIM not hit: %-24s @ 0x%08h",nm,peripheral_base(pe)+off);
            if(legal_complete(pe,off) && reg_complete_hits[key]==0)
              $display("  COMPLETE not hit: %-21s @ 0x%08h",nm,peripheral_base(pe)+off);
          end
        end
      end

      $display("[FCOV] Address-map coverage: %0.2f%%",address_map_cov.get_coverage());
      $display("[FCOV] Interrupt-source coverage: %0.2f%%",interrupt_source_cov.get_coverage());
      $display("[FCOV] Boot-stage coverage: %0.2f%%",boot_mode_cov.get_coverage());
      $display("[FCOV] Register-access covergroup (coarse peripheral/access bins): %0.2f%%",
        register_access_cov.get_coverage());

      $display("[FCOV] Enable/mode coverage: %0.2f%%",enable_mode_cov.get_coverage());

      if(missing_map!=0) $display("[FCOV INCOMPLETE] %0d address-map bins not hit",missing_map);
      if(missing_irq!=0) $display("[FCOV INCOMPLETE] %0d interrupt-source bins not hit",missing_irq);
      if(missing_boot!=0) $display("[FCOV INCOMPLETE] %0d boot-stage bins not hit",missing_boot);
      if(missing_reg_read+missing_reg_write+missing_claim+missing_complete!=0)
        $display("[FCOV INCOMPLETE] %0d legal register-access bins not hit",
          missing_reg_read+missing_reg_write+missing_claim+missing_complete);
      $display("=====================================================\n");
    end
  endtask
endmodule
