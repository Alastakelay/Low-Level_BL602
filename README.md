![Static Badge](https://img.shields.io/badge/RISC--V-processor-FDB515) ![Static Badge](https://img.shields.io/badge/Assembly-only-FF5800) ![Static Badge](https://img.shields.io/badge/License-GPL--3.0-FF0090) ![Static Badge](https://img.shields.io/badge/Embedded-device-50FF00)

# IMPORTANT!
# I sadly will not be able to contribute to this Repo for a **long time**  
# There's nothing I'd rather do than explore the mysteries of that interesting chip with shitty documentation, but that will have to wait until **summer 2026**  
# The reason being the lack of time that I freely dispose of as a human in modern-day society  
# In the meantime enjoy what little code I have for you, consult the General E24 [core documentation](https://www.sifive.com/document-file/e24-core-complex-manual), and submit issues or ideas for current or future projects

# Low-Level_BL602
This project aims to document and shed light on parts of the [**BouffaloLab602**](https://en.bouffalolab.com/product/?type=detail&id=1)  

>32-bit Wifi+BLE RV32IMAFC_Zifencei_Zicsr RISC-V [**SiFive E24 Core**](https://www.sifive.com/document-file/e24-core-complex-manual) (No bitmanip extension)

microcontroller through practical examples __written in Assembly__  

This Repository was created out of frustration due to a general lack of good documentation  
and practical bare-metal code examples for an otherwise amazing [**RISC-V**](https://riscv.org/) embedded chip  

My goal is to change this bit by byte by providing clean Assembly code,  
through which the reader can get an understanding of *how exactly* he or she is supposed to interface  
with internals and peripherals through [**MMIO**](https://en.wikipedia.org/wiki/Memory-mapped_I%2FO_and_port-mapped_I%2FO) without any confusing ***HALs*** or ***SDKs***  

>I will try to incrementally grow this collection of small programs and maintain it with my best efforts  
>All example code is tested and run on the [PineCone EVB](https://pine64.org/documentation/PineCone/)

## Online resources:
- PineCone [schematics](https://github.com/pine64/bl602-docs/blob/main/mirrored/Pine64%20BL602%20EVB%20Schematic%20ver%201.1.pdf)

### Interrupt controller used in **BL602** (Not a PLIC, but a NVIC called "CLIC"):
  - General E24 [core documentation](https://www.sifive.com/document-file/e24-core-complex-manual)
  - SiFive CLIC [scpecifications](https://github.com/marceg/clic-spec/tree/master?tab=readme-ov-file)
  - CLIC/CLINT [adress mapping](https://github.com/openshwprojects/OpenBL602/blob/master/components/platform/soc/bl602/bl602_std/bl602_std/RISCV/Core/Include/clic.h)

### Directly controlling [GPIO](https://gtker.com/running-assembly-on-the-bl602-risc-v-microcontroller-and-directly-controlling-gpio/)

### Docs from Bouffalo Lab:  
  - Reference [manual](https://github.com/bouffalolab/bl_docs/blob/main/BL602_RM/en/BL602_BL604_RM_1.2_en.pdf)
  - [Datasheet](https://github.com/bouffalolab/bl_docs/blob/main/BL602_DS/en/BL602_BL604_DS_1.6_en.pdf)
  - ISP [protocol](https://github.com/bouffalolab/bl_docs/blob/main/BL602_ISP/en/BL602_ISP_protocol.pdf)

### MMIO mapping and [hardware notes](https://github.com/tchebb/bl602-docs/tree/main/hardware_notes)

### RISC-V documentation:  
  - RISC-V Instruction [Encoder/Decoder](https://luplab.gitlab.io/rvcodecjs/)
  - RISC-V ISA [Manual](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/index.html)
  - Official ISA [Specs](https://riscv.org/specifications/ratified/) by RISC-V International

### Workflow:  
  - VSCodium [code editor](https://github.com/VSCodium/vscodium)
  - GCC
  - Blflash [flasher utility](https://github.com/spacemeowx2/blflash)
