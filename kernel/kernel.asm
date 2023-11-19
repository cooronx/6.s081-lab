
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	1cc78793          	addi	a5,a5,460 # 80006230 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	4e4080e7          	jalr	1252(ra) # 80002602 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	8d0080e7          	jalr	-1840(ra) # 80001a86 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	184080e7          	jalr	388(ra) # 8000234a <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	3aa080e7          	jalr	938(ra) # 800025ac <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	374080e7          	jalr	884(ra) # 80002658 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	098080e7          	jalr	152(ra) # 800024d0 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	0002d797          	auipc	a5,0x2d
    8000046e:	e9678793          	addi	a5,a5,-362 # 8002d300 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	c3e080e7          	jalr	-962(ra) # 800024d0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a2c080e7          	jalr	-1492(ra) # 8000234a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00031797          	auipc	a5,0x31
    80000a02:	60278793          	addi	a5,a5,1538 # 80032000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00031517          	auipc	a0,0x31
    80000ad2:	53250513          	addi	a0,a0,1330 # 80032000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	efa080e7          	jalr	-262(ra) # 80001a6a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	ec8080e7          	jalr	-312(ra) # 80001a6a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ebc080e7          	jalr	-324(ra) # 80001a6a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	ea4080e7          	jalr	-348(ra) # 80001a6a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	e64080e7          	jalr	-412(ra) # 80001a6a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	e38080e7          	jalr	-456(ra) # 80001a6a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	bce080e7          	jalr	-1074(ra) # 80001a5a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	bb2080e7          	jalr	-1102(ra) # 80001a5a <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	8ce080e7          	jalr	-1842(ra) # 80002798 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	39e080e7          	jalr	926(ra) # 80006270 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	138080e7          	jalr	312(ra) # 80002012 <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	a88080e7          	jalr	-1400(ra) # 800019c2 <procinit>
    trapinit();      // trap vectors
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	82e080e7          	jalr	-2002(ra) # 80002770 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	84e080e7          	jalr	-1970(ra) # 80002798 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	308080e7          	jalr	776(ra) # 8000625a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	316080e7          	jalr	790(ra) # 80006270 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	0f8080e7          	jalr	248(ra) # 8000305a <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	788080e7          	jalr	1928(ra) # 800036f2 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	750080e7          	jalr	1872(ra) # 800046c2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	418080e7          	jalr	1048(ra) # 80006392 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	dce080e7          	jalr	-562(ra) # 80001d50 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	708080e7          	jalr	1800(ra) # 8000192c <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0735e163          	bltu	a1,s3,800012e8 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012d2:	00c79513          	slli	a0,a5,0xc
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	714080e7          	jalr	1812(ra) # 800009ea <kfree>
    *pte = 0;
    800012de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	9956                	add	s2,s2,s5
    800012e4:	fb3973e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012e8:	4601                	li	a2,0
    800012ea:	85ca                	mv	a1,s2
    800012ec:	8552                	mv	a0,s4
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	cd0080e7          	jalr	-816(ra) # 80000fbe <walk>
    800012f6:	84aa                	mv	s1,a0
    800012f8:	dd45                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fa:	611c                	ld	a5,0(a0)
    800012fc:	0017f713          	andi	a4,a5,1
    80001300:	d36d                	beqz	a4,800012e2 <uvmunmap+0x88>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001302:	3ff7f713          	andi	a4,a5,1023
    80001306:	fb770de3          	beq	a4,s7,800012c0 <uvmunmap+0x66>
    if(do_free){
    8000130a:	fc0b0ae3          	beqz	s6,800012de <uvmunmap+0x84>
    8000130e:	b7c9                	j	800012d0 <uvmunmap+0x76>

0000000080001310 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	7cc080e7          	jalr	1996(ra) # 80000ae6 <kalloc>
    80001322:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001324:	c519                	beqz	a0,80001332 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	9a8080e7          	jalr	-1624(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001332:	8526                	mv	a0,s1
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f406                	sd	ra,40(sp)
    80001342:	f022                	sd	s0,32(sp)
    80001344:	ec26                	sd	s1,24(sp)
    80001346:	e84a                	sd	s2,16(sp)
    80001348:	e44e                	sd	s3,8(sp)
    8000134a:	e052                	sd	s4,0(sp)
    8000134c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134e:	6785                	lui	a5,0x1
    80001350:	04f67863          	bgeu	a2,a5,800013a0 <uvminit+0x62>
    80001354:	8a2a                	mv	s4,a0
    80001356:	89ae                	mv	s3,a1
    80001358:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	78c080e7          	jalr	1932(ra) # 80000ae6 <kalloc>
    80001362:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	96a080e7          	jalr	-1686(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001370:	4779                	li	a4,30
    80001372:	86ca                	mv	a3,s2
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	d2c080e7          	jalr	-724(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001382:	8626                	mv	a2,s1
    80001384:	85ce                	mv	a1,s3
    80001386:	854a                	mv	a0,s2
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	9aa080e7          	jalr	-1622(ra) # 80000d32 <memmove>
}
    80001390:	70a2                	ld	ra,40(sp)
    80001392:	7402                	ld	s0,32(sp)
    80001394:	64e2                	ld	s1,24(sp)
    80001396:	6942                	ld	s2,16(sp)
    80001398:	69a2                	ld	s3,8(sp)
    8000139a:	6a02                	ld	s4,0(sp)
    8000139c:	6145                	addi	sp,sp,48
    8000139e:	8082                	ret
    panic("inituvm: more than a page");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8850513          	addi	a0,a0,-632 # 80008128 <digits+0xe8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	188080e7          	jalr	392(ra) # 80000530 <panic>

00000000800013b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013bc:	00b67d63          	bgeu	a2,a1,800013d6 <uvmdealloc+0x26>
    800013c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	17fd                	addi	a5,a5,-1
    800013c6:	00f60733          	add	a4,a2,a5
    800013ca:	767d                	lui	a2,0xfffff
    800013cc:	8f71                	and	a4,a4,a2
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	8ff1                	and	a5,a5,a2
    800013d2:	00f76863          	bltu	a4,a5,800013e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e2:	8f99                	sub	a5,a5,a4
    800013e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e6:	4685                	li	a3,1
    800013e8:	0007861b          	sext.w	a2,a5
    800013ec:	85ba                	mv	a1,a4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	e6c080e7          	jalr	-404(ra) # 8000125a <uvmunmap>
    800013f6:	b7c5                	j	800013d6 <uvmdealloc+0x26>

00000000800013f8 <uvmalloc>:
  if(newsz < oldsz)
    800013f8:	0ab66163          	bltu	a2,a1,8000149a <uvmalloc+0xa2>
{
    800013fc:	7139                	addi	sp,sp,-64
    800013fe:	fc06                	sd	ra,56(sp)
    80001400:	f822                	sd	s0,48(sp)
    80001402:	f426                	sd	s1,40(sp)
    80001404:	f04a                	sd	s2,32(sp)
    80001406:	ec4e                	sd	s3,24(sp)
    80001408:	e852                	sd	s4,16(sp)
    8000140a:	e456                	sd	s5,8(sp)
    8000140c:	0080                	addi	s0,sp,64
    8000140e:	8aaa                	mv	s5,a0
    80001410:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001412:	6985                	lui	s3,0x1
    80001414:	19fd                	addi	s3,s3,-1
    80001416:	95ce                	add	a1,a1,s3
    80001418:	79fd                	lui	s3,0xfffff
    8000141a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141e:	08c9f063          	bgeu	s3,a2,8000149e <uvmalloc+0xa6>
    80001422:	894e                	mv	s2,s3
    mem = kalloc();
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	6c2080e7          	jalr	1730(ra) # 80000ae6 <kalloc>
    8000142c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000142e:	c51d                	beqz	a0,8000145c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001430:	6605                	lui	a2,0x1
    80001432:	4581                	li	a1,0
    80001434:	00000097          	auipc	ra,0x0
    80001438:	89e080e7          	jalr	-1890(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000143c:	4779                	li	a4,30
    8000143e:	86a6                	mv	a3,s1
    80001440:	6605                	lui	a2,0x1
    80001442:	85ca                	mv	a1,s2
    80001444:	8556                	mv	a0,s5
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	c60080e7          	jalr	-928(ra) # 800010a6 <mappages>
    8000144e:	e905                	bnez	a0,8000147e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	6785                	lui	a5,0x1
    80001452:	993e                	add	s2,s2,a5
    80001454:	fd4968e3          	bltu	s2,s4,80001424 <uvmalloc+0x2c>
  return newsz;
    80001458:	8552                	mv	a0,s4
    8000145a:	a809                	j	8000146c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000145c:	864e                	mv	a2,s3
    8000145e:	85ca                	mv	a1,s2
    80001460:	8556                	mv	a0,s5
    80001462:	00000097          	auipc	ra,0x0
    80001466:	f4e080e7          	jalr	-178(ra) # 800013b0 <uvmdealloc>
      return 0;
    8000146a:	4501                	li	a0,0
}
    8000146c:	70e2                	ld	ra,56(sp)
    8000146e:	7442                	ld	s0,48(sp)
    80001470:	74a2                	ld	s1,40(sp)
    80001472:	7902                	ld	s2,32(sp)
    80001474:	69e2                	ld	s3,24(sp)
    80001476:	6a42                	ld	s4,16(sp)
    80001478:	6aa2                	ld	s5,8(sp)
    8000147a:	6121                	addi	sp,sp,64
    8000147c:	8082                	ret
      kfree(mem);
    8000147e:	8526                	mv	a0,s1
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	56a080e7          	jalr	1386(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001488:	864e                	mv	a2,s3
    8000148a:	85ca                	mv	a1,s2
    8000148c:	8556                	mv	a0,s5
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f22080e7          	jalr	-222(ra) # 800013b0 <uvmdealloc>
      return 0;
    80001496:	4501                	li	a0,0
    80001498:	bfd1                	j	8000146c <uvmalloc+0x74>
    return oldsz;
    8000149a:	852e                	mv	a0,a1
}
    8000149c:	8082                	ret
  return newsz;
    8000149e:	8532                	mv	a0,a2
    800014a0:	b7f1                	j	8000146c <uvmalloc+0x74>

00000000800014a2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a2:	7179                	addi	sp,sp,-48
    800014a4:	f406                	sd	ra,40(sp)
    800014a6:	f022                	sd	s0,32(sp)
    800014a8:	ec26                	sd	s1,24(sp)
    800014aa:	e84a                	sd	s2,16(sp)
    800014ac:	e44e                	sd	s3,8(sp)
    800014ae:	e052                	sd	s4,0(sp)
    800014b0:	1800                	addi	s0,sp,48
    800014b2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b4:	84aa                	mv	s1,a0
    800014b6:	6905                	lui	s2,0x1
    800014b8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ba:	4985                	li	s3,1
    800014bc:	a821                	j	800014d4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014be:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014c0:	0532                	slli	a0,a0,0xc
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	fe0080e7          	jalr	-32(ra) # 800014a2 <freewalk>
      pagetable[i] = 0;
    800014ca:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ce:	04a1                	addi	s1,s1,8
    800014d0:	03248163          	beq	s1,s2,800014f2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014d4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d6:	00f57793          	andi	a5,a0,15
    800014da:	ff3782e3          	beq	a5,s3,800014be <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014de:	8905                	andi	a0,a0,1
    800014e0:	d57d                	beqz	a0,800014ce <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e2:	00007517          	auipc	a0,0x7
    800014e6:	c6650513          	addi	a0,a0,-922 # 80008148 <digits+0x108>
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	046080e7          	jalr	70(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    800014f2:	8552                	mv	a0,s4
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	4f6080e7          	jalr	1270(ra) # 800009ea <kfree>
}
    800014fc:	70a2                	ld	ra,40(sp)
    800014fe:	7402                	ld	s0,32(sp)
    80001500:	64e2                	ld	s1,24(sp)
    80001502:	6942                	ld	s2,16(sp)
    80001504:	69a2                	ld	s3,8(sp)
    80001506:	6a02                	ld	s4,0(sp)
    80001508:	6145                	addi	sp,sp,48
    8000150a:	8082                	ret

000000008000150c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000150c:	1101                	addi	sp,sp,-32
    8000150e:	ec06                	sd	ra,24(sp)
    80001510:	e822                	sd	s0,16(sp)
    80001512:	e426                	sd	s1,8(sp)
    80001514:	1000                	addi	s0,sp,32
    80001516:	84aa                	mv	s1,a0
  if(sz > 0)
    80001518:	e999                	bnez	a1,8000152e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000151a:	8526                	mv	a0,s1
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f86080e7          	jalr	-122(ra) # 800014a2 <freewalk>
}
    80001524:	60e2                	ld	ra,24(sp)
    80001526:	6442                	ld	s0,16(sp)
    80001528:	64a2                	ld	s1,8(sp)
    8000152a:	6105                	addi	sp,sp,32
    8000152c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000152e:	6605                	lui	a2,0x1
    80001530:	167d                	addi	a2,a2,-1
    80001532:	962e                	add	a2,a2,a1
    80001534:	4685                	li	a3,1
    80001536:	8231                	srli	a2,a2,0xc
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	d20080e7          	jalr	-736(ra) # 8000125a <uvmunmap>
    80001542:	bfe1                	j	8000151a <uvmfree+0xe>

0000000080001544 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001544:	c269                	beqz	a2,80001606 <uvmcopy+0xc2>
{
    80001546:	715d                	addi	sp,sp,-80
    80001548:	e486                	sd	ra,72(sp)
    8000154a:	e0a2                	sd	s0,64(sp)
    8000154c:	fc26                	sd	s1,56(sp)
    8000154e:	f84a                	sd	s2,48(sp)
    80001550:	f44e                	sd	s3,40(sp)
    80001552:	f052                	sd	s4,32(sp)
    80001554:	ec56                	sd	s5,24(sp)
    80001556:	e85a                	sd	s6,16(sp)
    80001558:	e45e                	sd	s7,8(sp)
    8000155a:	0880                	addi	s0,sp,80
    8000155c:	8aaa                	mv	s5,a0
    8000155e:	8b2e                	mv	s6,a1
    80001560:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001562:	4481                	li	s1,0
    80001564:	a829                	j	8000157e <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	bf250513          	addi	a0,a0,-1038 # 80008158 <digits+0x118>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fc2080e7          	jalr	-62(ra) # 80000530 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	94be                	add	s1,s1,a5
    8000157a:	0944f463          	bgeu	s1,s4,80001602 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000157e:	4601                	li	a2,0
    80001580:	85a6                	mv	a1,s1
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	a3a080e7          	jalr	-1478(ra) # 80000fbe <walk>
    8000158c:	dd69                	beqz	a0,80001566 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0){
    8000158e:	6118                	ld	a4,0(a0)
    80001590:	00177793          	andi	a5,a4,1
    80001594:	d3ed                	beqz	a5,80001576 <uvmcopy+0x32>
      continue;
    }
    pa = PTE2PA(*pte);
    80001596:	00a75593          	srli	a1,a4,0xa
    8000159a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000159e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	544080e7          	jalr	1348(ra) # 80000ae6 <kalloc>
    800015aa:	89aa                	mv	s3,a0
    800015ac:	c515                	beqz	a0,800015d8 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	85de                	mv	a1,s7
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	780080e7          	jalr	1920(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ba:	874a                	mv	a4,s2
    800015bc:	86ce                	mv	a3,s3
    800015be:	6605                	lui	a2,0x1
    800015c0:	85a6                	mv	a1,s1
    800015c2:	855a                	mv	a0,s6
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	ae2080e7          	jalr	-1310(ra) # 800010a6 <mappages>
    800015cc:	d54d                	beqz	a0,80001576 <uvmcopy+0x32>
      kfree(mem);
    800015ce:	854e                	mv	a0,s3
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d8:	4685                	li	a3,1
    800015da:	00c4d613          	srli	a2,s1,0xc
    800015de:	4581                	li	a1,0
    800015e0:	855a                	mv	a0,s6
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	c78080e7          	jalr	-904(ra) # 8000125a <uvmunmap>
  return -1;
    800015ea:	557d                	li	a0,-1
}
    800015ec:	60a6                	ld	ra,72(sp)
    800015ee:	6406                	ld	s0,64(sp)
    800015f0:	74e2                	ld	s1,56(sp)
    800015f2:	7942                	ld	s2,48(sp)
    800015f4:	79a2                	ld	s3,40(sp)
    800015f6:	7a02                	ld	s4,32(sp)
    800015f8:	6ae2                	ld	s5,24(sp)
    800015fa:	6b42                	ld	s6,16(sp)
    800015fc:	6ba2                	ld	s7,8(sp)
    800015fe:	6161                	addi	sp,sp,80
    80001600:	8082                	ret
  return 0;
    80001602:	4501                	li	a0,0
    80001604:	b7e5                	j	800015ec <uvmcopy+0xa8>
    80001606:	4501                	li	a0,0
}
    80001608:	8082                	ret

000000008000160a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160a:	1141                	addi	sp,sp,-16
    8000160c:	e406                	sd	ra,8(sp)
    8000160e:	e022                	sd	s0,0(sp)
    80001610:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001612:	4601                	li	a2,0
    80001614:	00000097          	auipc	ra,0x0
    80001618:	9aa080e7          	jalr	-1622(ra) # 80000fbe <walk>
  if(pte == 0)
    8000161c:	c901                	beqz	a0,8000162c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000161e:	611c                	ld	a5,0(a0)
    80001620:	9bbd                	andi	a5,a5,-17
    80001622:	e11c                	sd	a5,0(a0)
}
    80001624:	60a2                	ld	ra,8(sp)
    80001626:	6402                	ld	s0,0(sp)
    80001628:	0141                	addi	sp,sp,16
    8000162a:	8082                	ret
    panic("uvmclear");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b4c50513          	addi	a0,a0,-1204 # 80008178 <digits+0x138>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	efc080e7          	jalr	-260(ra) # 80000530 <panic>

000000008000163c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163c:	c6bd                	beqz	a3,800016aa <copyout+0x6e>
{
    8000163e:	715d                	addi	sp,sp,-80
    80001640:	e486                	sd	ra,72(sp)
    80001642:	e0a2                	sd	s0,64(sp)
    80001644:	fc26                	sd	s1,56(sp)
    80001646:	f84a                	sd	s2,48(sp)
    80001648:	f44e                	sd	s3,40(sp)
    8000164a:	f052                	sd	s4,32(sp)
    8000164c:	ec56                	sd	s5,24(sp)
    8000164e:	e85a                	sd	s6,16(sp)
    80001650:	e45e                	sd	s7,8(sp)
    80001652:	e062                	sd	s8,0(sp)
    80001654:	0880                	addi	s0,sp,80
    80001656:	8b2a                	mv	s6,a0
    80001658:	8c2e                	mv	s8,a1
    8000165a:	8a32                	mv	s4,a2
    8000165c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000165e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001660:	6a85                	lui	s5,0x1
    80001662:	a015                	j	80001686 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001664:	9562                	add	a0,a0,s8
    80001666:	0004861b          	sext.w	a2,s1
    8000166a:	85d2                	mv	a1,s4
    8000166c:	41250533          	sub	a0,a0,s2
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	6c2080e7          	jalr	1730(ra) # 80000d32 <memmove>

    len -= n;
    80001678:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000167e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001682:	02098263          	beqz	s3,800016a6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001686:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168a:	85ca                	mv	a1,s2
    8000168c:	855a                	mv	a0,s6
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	9d6080e7          	jalr	-1578(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001696:	cd01                	beqz	a0,800016ae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001698:	418904b3          	sub	s1,s2,s8
    8000169c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000169e:	fc99f3e3          	bgeu	s3,s1,80001664 <copyout+0x28>
    800016a2:	84ce                	mv	s1,s3
    800016a4:	b7c1                	j	80001664 <copyout+0x28>
  }
  return 0;
    800016a6:	4501                	li	a0,0
    800016a8:	a021                	j	800016b0 <copyout+0x74>
    800016aa:	4501                	li	a0,0
}
    800016ac:	8082                	ret
      return -1;
    800016ae:	557d                	li	a0,-1
}
    800016b0:	60a6                	ld	ra,72(sp)
    800016b2:	6406                	ld	s0,64(sp)
    800016b4:	74e2                	ld	s1,56(sp)
    800016b6:	7942                	ld	s2,48(sp)
    800016b8:	79a2                	ld	s3,40(sp)
    800016ba:	7a02                	ld	s4,32(sp)
    800016bc:	6ae2                	ld	s5,24(sp)
    800016be:	6b42                	ld	s6,16(sp)
    800016c0:	6ba2                	ld	s7,8(sp)
    800016c2:	6c02                	ld	s8,0(sp)
    800016c4:	6161                	addi	sp,sp,80
    800016c6:	8082                	ret

00000000800016c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c8:	c6bd                	beqz	a3,80001736 <copyin+0x6e>
{
    800016ca:	715d                	addi	sp,sp,-80
    800016cc:	e486                	sd	ra,72(sp)
    800016ce:	e0a2                	sd	s0,64(sp)
    800016d0:	fc26                	sd	s1,56(sp)
    800016d2:	f84a                	sd	s2,48(sp)
    800016d4:	f44e                	sd	s3,40(sp)
    800016d6:	f052                	sd	s4,32(sp)
    800016d8:	ec56                	sd	s5,24(sp)
    800016da:	e85a                	sd	s6,16(sp)
    800016dc:	e45e                	sd	s7,8(sp)
    800016de:	e062                	sd	s8,0(sp)
    800016e0:	0880                	addi	s0,sp,80
    800016e2:	8b2a                	mv	s6,a0
    800016e4:	8a2e                	mv	s4,a1
    800016e6:	8c32                	mv	s8,a2
    800016e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ec:	6a85                	lui	s5,0x1
    800016ee:	a015                	j	80001712 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f0:	9562                	add	a0,a0,s8
    800016f2:	0004861b          	sext.w	a2,s1
    800016f6:	412505b3          	sub	a1,a0,s2
    800016fa:	8552                	mv	a0,s4
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	636080e7          	jalr	1590(ra) # 80000d32 <memmove>

    len -= n;
    80001704:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001708:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170e:	02098263          	beqz	s3,80001732 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001712:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001716:	85ca                	mv	a1,s2
    80001718:	855a                	mv	a0,s6
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	94a080e7          	jalr	-1718(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001722:	cd01                	beqz	a0,8000173a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001724:	418904b3          	sub	s1,s2,s8
    80001728:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172a:	fc99f3e3          	bgeu	s3,s1,800016f0 <copyin+0x28>
    8000172e:	84ce                	mv	s1,s3
    80001730:	b7c1                	j	800016f0 <copyin+0x28>
  }
  return 0;
    80001732:	4501                	li	a0,0
    80001734:	a021                	j	8000173c <copyin+0x74>
    80001736:	4501                	li	a0,0
}
    80001738:	8082                	ret
      return -1;
    8000173a:	557d                	li	a0,-1
}
    8000173c:	60a6                	ld	ra,72(sp)
    8000173e:	6406                	ld	s0,64(sp)
    80001740:	74e2                	ld	s1,56(sp)
    80001742:	7942                	ld	s2,48(sp)
    80001744:	79a2                	ld	s3,40(sp)
    80001746:	7a02                	ld	s4,32(sp)
    80001748:	6ae2                	ld	s5,24(sp)
    8000174a:	6b42                	ld	s6,16(sp)
    8000174c:	6ba2                	ld	s7,8(sp)
    8000174e:	6c02                	ld	s8,0(sp)
    80001750:	6161                	addi	sp,sp,80
    80001752:	8082                	ret

0000000080001754 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001754:	c6c5                	beqz	a3,800017fc <copyinstr+0xa8>
{
    80001756:	715d                	addi	sp,sp,-80
    80001758:	e486                	sd	ra,72(sp)
    8000175a:	e0a2                	sd	s0,64(sp)
    8000175c:	fc26                	sd	s1,56(sp)
    8000175e:	f84a                	sd	s2,48(sp)
    80001760:	f44e                	sd	s3,40(sp)
    80001762:	f052                	sd	s4,32(sp)
    80001764:	ec56                	sd	s5,24(sp)
    80001766:	e85a                	sd	s6,16(sp)
    80001768:	e45e                	sd	s7,8(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8a2a                	mv	s4,a0
    8000176e:	8b2e                	mv	s6,a1
    80001770:	8bb2                	mv	s7,a2
    80001772:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001774:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001776:	6985                	lui	s3,0x1
    80001778:	a035                	j	800017a4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000177e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001780:	0017b793          	seqz	a5,a5
    80001784:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001788:	60a6                	ld	ra,72(sp)
    8000178a:	6406                	ld	s0,64(sp)
    8000178c:	74e2                	ld	s1,56(sp)
    8000178e:	7942                	ld	s2,48(sp)
    80001790:	79a2                	ld	s3,40(sp)
    80001792:	7a02                	ld	s4,32(sp)
    80001794:	6ae2                	ld	s5,24(sp)
    80001796:	6b42                	ld	s6,16(sp)
    80001798:	6ba2                	ld	s7,8(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000179e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a2:	c8a9                	beqz	s1,800017f4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017a8:	85ca                	mv	a1,s2
    800017aa:	8552                	mv	a0,s4
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	8b8080e7          	jalr	-1864(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017b4:	c131                	beqz	a0,800017f8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017b6:	41790833          	sub	a6,s2,s7
    800017ba:	984e                	add	a6,a6,s3
    if(n > max)
    800017bc:	0104f363          	bgeu	s1,a6,800017c2 <copyinstr+0x6e>
    800017c0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c2:	955e                	add	a0,a0,s7
    800017c4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017c8:	fc080be3          	beqz	a6,8000179e <copyinstr+0x4a>
    800017cc:	985a                	add	a6,a6,s6
    800017ce:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d0:	41650633          	sub	a2,a0,s6
    800017d4:	14fd                	addi	s1,s1,-1
    800017d6:	9b26                	add	s6,s6,s1
    800017d8:	00f60733          	add	a4,a2,a5
    800017dc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    800017e0:	df49                	beqz	a4,8000177a <copyinstr+0x26>
        *dst = *p;
    800017e2:	00e78023          	sb	a4,0(a5)
      --max;
    800017e6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ea:	0785                	addi	a5,a5,1
    while(n > 0){
    800017ec:	ff0796e3          	bne	a5,a6,800017d8 <copyinstr+0x84>
      dst++;
    800017f0:	8b42                	mv	s6,a6
    800017f2:	b775                	j	8000179e <copyinstr+0x4a>
    800017f4:	4781                	li	a5,0
    800017f6:	b769                	j	80001780 <copyinstr+0x2c>
      return -1;
    800017f8:	557d                	li	a0,-1
    800017fa:	b779                	j	80001788 <copyinstr+0x34>
  int got_null = 0;
    800017fc:	4781                	li	a5,0
  if(got_null){
    800017fe:	0017b793          	seqz	a5,a5
    80001802:	40f00533          	neg	a0,a5
}
    80001806:	8082                	ret

0000000080001808 <vmprint_helper>:


void vmprint_helper(pagetable_t pagetable, int depth) {
    80001808:	715d                	addi	sp,sp,-80
    8000180a:	e486                	sd	ra,72(sp)
    8000180c:	e0a2                	sd	s0,64(sp)
    8000180e:	fc26                	sd	s1,56(sp)
    80001810:	f84a                	sd	s2,48(sp)
    80001812:	f44e                	sd	s3,40(sp)
    80001814:	f052                	sd	s4,32(sp)
    80001816:	ec56                	sd	s5,24(sp)
    80001818:	e85a                	sd	s6,16(sp)
    8000181a:	e45e                	sd	s7,8(sp)
    8000181c:	e062                	sd	s8,0(sp)
    8000181e:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    80001820:	fff5871b          	addiw	a4,a1,-1
    80001824:	4789                	li	a5,2
    80001826:	02e7e463          	bltu	a5,a4,8000184e <vmprint_helper+0x46>
    8000182a:	89aa                	mv	s3,a0
    8000182c:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) { //是一个有效的PTE
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    8000182e:	00359793          	slli	a5,a1,0x3
    80001832:	00007b17          	auipc	s6,0x7
    80001836:	9beb0b13          	addi	s6,s6,-1602 # 800081f0 <indent.1667>
    8000183a:	9b3e                	add	s6,s6,a5
    8000183c:	00007b97          	auipc	s7,0x7
    80001840:	96cb8b93          	addi	s7,s7,-1684 # 800081a8 <digits+0x168>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table 并且是间接层PTE
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1); // 递归, 深度+1
    80001844:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    80001848:	20000a93          	li	s5,512
    8000184c:	a01d                	j	80001872 <vmprint_helper+0x6a>
    panic("vmprint_helper: depth error");
    8000184e:	00007517          	auipc	a0,0x7
    80001852:	93a50513          	addi	a0,a0,-1734 # 80008188 <digits+0x148>
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	cda080e7          	jalr	-806(ra) # 80000530 <panic>
        vmprint_helper((pagetable_t)child, depth+1); // 递归, 深度+1
    8000185e:	85e2                	mv	a1,s8
    80001860:	8552                	mv	a0,s4
    80001862:	00000097          	auipc	ra,0x0
    80001866:	fa6080e7          	jalr	-90(ra) # 80001808 <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    8000186a:	2905                	addiw	s2,s2,1
    8000186c:	09a1                	addi	s3,s3,8
    8000186e:	03590763          	beq	s2,s5,8000189c <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    80001872:	0009b483          	ld	s1,0(s3) # 1000 <_entry-0x7ffff000>
    if (pte & PTE_V) { //是一个有效的PTE
    80001876:	0014f793          	andi	a5,s1,1
    8000187a:	dbe5                	beqz	a5,8000186a <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    8000187c:	00a4da13          	srli	s4,s1,0xa
    80001880:	0a32                	slli	s4,s4,0xc
    80001882:	8752                	mv	a4,s4
    80001884:	86a6                	mv	a3,s1
    80001886:	864a                	mv	a2,s2
    80001888:	000b3583          	ld	a1,0(s6)
    8000188c:	855e                	mv	a0,s7
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	cec080e7          	jalr	-788(ra) # 8000057a <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001896:	88b9                	andi	s1,s1,14
    80001898:	f8e9                	bnez	s1,8000186a <vmprint_helper+0x62>
    8000189a:	b7d1                	j	8000185e <vmprint_helper+0x56>
      }
    }
  }
}
    8000189c:	60a6                	ld	ra,72(sp)
    8000189e:	6406                	ld	s0,64(sp)
    800018a0:	74e2                	ld	s1,56(sp)
    800018a2:	7942                	ld	s2,48(sp)
    800018a4:	79a2                	ld	s3,40(sp)
    800018a6:	7a02                	ld	s4,32(sp)
    800018a8:	6ae2                	ld	s5,24(sp)
    800018aa:	6b42                	ld	s6,16(sp)
    800018ac:	6ba2                	ld	s7,8(sp)
    800018ae:	6c02                	ld	s8,0(sp)
    800018b0:	6161                	addi	sp,sp,80
    800018b2:	8082                	ret

00000000800018b4 <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    800018b4:	1101                	addi	sp,sp,-32
    800018b6:	ec06                	sd	ra,24(sp)
    800018b8:	e822                	sd	s0,16(sp)
    800018ba:	e426                	sd	s1,8(sp)
    800018bc:	1000                	addi	s0,sp,32
    800018be:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800018c0:	85aa                	mv	a1,a0
    800018c2:	00007517          	auipc	a0,0x7
    800018c6:	8fe50513          	addi	a0,a0,-1794 # 800081c0 <digits+0x180>
    800018ca:	fffff097          	auipc	ra,0xfffff
    800018ce:	cb0080e7          	jalr	-848(ra) # 8000057a <printf>
  vmprint_helper(pagetable, 1);
    800018d2:	4585                	li	a1,1
    800018d4:	8526                	mv	a0,s1
    800018d6:	00000097          	auipc	ra,0x0
    800018da:	f32080e7          	jalr	-206(ra) # 80001808 <vmprint_helper>
    800018de:	60e2                	ld	ra,24(sp)
    800018e0:	6442                	ld	s0,16(sp)
    800018e2:	64a2                	ld	s1,8(sp)
    800018e4:	6105                	addi	sp,sp,32
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	268080e7          	jalr	616(ra) # 80000b5c <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	90250513          	addi	a0,a0,-1790 # 80008210 <indent.1667+0x20>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c1a080e7          	jalr	-998(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000192c:	7139                	addi	sp,sp,-64
    8000192e:	fc06                	sd	ra,56(sp)
    80001930:	f822                	sd	s0,48(sp)
    80001932:	f426                	sd	s1,40(sp)
    80001934:	f04a                	sd	s2,32(sp)
    80001936:	ec4e                	sd	s3,24(sp)
    80001938:	e852                	sd	s4,16(sp)
    8000193a:	e456                	sd	s5,8(sp)
    8000193c:	e05a                	sd	s6,0(sp)
    8000193e:	0080                	addi	s0,sp,64
    80001940:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	00010497          	auipc	s1,0x10
    80001946:	d7648493          	addi	s1,s1,-650 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000194a:	8b26                	mv	s6,s1
    8000194c:	00006a97          	auipc	s5,0x6
    80001950:	6b4a8a93          	addi	s5,s5,1716 # 80008000 <etext>
    80001954:	04000937          	lui	s2,0x4000
    80001958:	197d                	addi	s2,s2,-1
    8000195a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00021a17          	auipc	s4,0x21
    80001960:	75ca0a13          	addi	s4,s4,1884 # 800230b8 <tickslock>
    char *pa = kalloc();
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	182080e7          	jalr	386(ra) # 80000ae6 <kalloc>
    8000196c:	862a                	mv	a2,a0
    if(pa == 0)
    8000196e:	c131                	beqz	a0,800019b2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001970:	416485b3          	sub	a1,s1,s6
    80001974:	858d                	srai	a1,a1,0x3
    80001976:	000ab783          	ld	a5,0(s5)
    8000197a:	02f585b3          	mul	a1,a1,a5
    8000197e:	2585                	addiw	a1,a1,1
    80001980:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001984:	4719                	li	a4,6
    80001986:	6685                	lui	a3,0x1
    80001988:	40b905b3          	sub	a1,s2,a1
    8000198c:	854e                	mv	a0,s3
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	7a6080e7          	jalr	1958(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	46848493          	addi	s1,s1,1128
    8000199a:	fd4495e3          	bne	s1,s4,80001964 <proc_mapstacks+0x38>
}
    8000199e:	70e2                	ld	ra,56(sp)
    800019a0:	7442                	ld	s0,48(sp)
    800019a2:	74a2                	ld	s1,40(sp)
    800019a4:	7902                	ld	s2,32(sp)
    800019a6:	69e2                	ld	s3,24(sp)
    800019a8:	6a42                	ld	s4,16(sp)
    800019aa:	6aa2                	ld	s5,8(sp)
    800019ac:	6b02                	ld	s6,0(sp)
    800019ae:	6121                	addi	sp,sp,64
    800019b0:	8082                	ret
      panic("kalloc");
    800019b2:	00007517          	auipc	a0,0x7
    800019b6:	86650513          	addi	a0,a0,-1946 # 80008218 <indent.1667+0x28>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	b76080e7          	jalr	-1162(ra) # 80000530 <panic>

00000000800019c2 <procinit>:
{
    800019c2:	7139                	addi	sp,sp,-64
    800019c4:	fc06                	sd	ra,56(sp)
    800019c6:	f822                	sd	s0,48(sp)
    800019c8:	f426                	sd	s1,40(sp)
    800019ca:	f04a                	sd	s2,32(sp)
    800019cc:	ec4e                	sd	s3,24(sp)
    800019ce:	e852                	sd	s4,16(sp)
    800019d0:	e456                	sd	s5,8(sp)
    800019d2:	e05a                	sd	s6,0(sp)
    800019d4:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    800019d6:	00007597          	auipc	a1,0x7
    800019da:	84a58593          	addi	a1,a1,-1974 # 80008220 <indent.1667+0x30>
    800019de:	00010517          	auipc	a0,0x10
    800019e2:	8c250513          	addi	a0,a0,-1854 # 800112a0 <pid_lock>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	160080e7          	jalr	352(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ee:	00010497          	auipc	s1,0x10
    800019f2:	cca48493          	addi	s1,s1,-822 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    800019f6:	00007b17          	auipc	s6,0x7
    800019fa:	832b0b13          	addi	s6,s6,-1998 # 80008228 <indent.1667+0x38>
      p->kstack = KSTACK((int) (p - proc));
    800019fe:	8aa6                	mv	s5,s1
    80001a00:	00006a17          	auipc	s4,0x6
    80001a04:	600a0a13          	addi	s4,s4,1536 # 80008000 <etext>
    80001a08:	04000937          	lui	s2,0x4000
    80001a0c:	197d                	addi	s2,s2,-1
    80001a0e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a10:	00021997          	auipc	s3,0x21
    80001a14:	6a898993          	addi	s3,s3,1704 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    80001a18:	85da                	mv	a1,s6
    80001a1a:	8526                	mv	a0,s1
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	12a080e7          	jalr	298(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a24:	415487b3          	sub	a5,s1,s5
    80001a28:	878d                	srai	a5,a5,0x3
    80001a2a:	000a3703          	ld	a4,0(s4)
    80001a2e:	02e787b3          	mul	a5,a5,a4
    80001a32:	2785                	addiw	a5,a5,1
    80001a34:	00d7979b          	slliw	a5,a5,0xd
    80001a38:	40f907b3          	sub	a5,s2,a5
    80001a3c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3e:	46848493          	addi	s1,s1,1128
    80001a42:	fd349be3          	bne	s1,s3,80001a18 <procinit+0x56>
}
    80001a46:	70e2                	ld	ra,56(sp)
    80001a48:	7442                	ld	s0,48(sp)
    80001a4a:	74a2                	ld	s1,40(sp)
    80001a4c:	7902                	ld	s2,32(sp)
    80001a4e:	69e2                	ld	s3,24(sp)
    80001a50:	6a42                	ld	s4,16(sp)
    80001a52:	6aa2                	ld	s5,8(sp)
    80001a54:	6b02                	ld	s6,0(sp)
    80001a56:	6121                	addi	sp,sp,64
    80001a58:	8082                	ret

0000000080001a5a <cpuid>:
{
    80001a5a:	1141                	addi	sp,sp,-16
    80001a5c:	e422                	sd	s0,8(sp)
    80001a5e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a60:	8512                	mv	a0,tp
}
    80001a62:	2501                	sext.w	a0,a0
    80001a64:	6422                	ld	s0,8(sp)
    80001a66:	0141                	addi	sp,sp,16
    80001a68:	8082                	ret

0000000080001a6a <mycpu>:
mycpu(void) {
    80001a6a:	1141                	addi	sp,sp,-16
    80001a6c:	e422                	sd	s0,8(sp)
    80001a6e:	0800                	addi	s0,sp,16
    80001a70:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a72:	2781                	sext.w	a5,a5
    80001a74:	079e                	slli	a5,a5,0x7
}
    80001a76:	00010517          	auipc	a0,0x10
    80001a7a:	84250513          	addi	a0,a0,-1982 # 800112b8 <cpus>
    80001a7e:	953e                	add	a0,a0,a5
    80001a80:	6422                	ld	s0,8(sp)
    80001a82:	0141                	addi	sp,sp,16
    80001a84:	8082                	ret

0000000080001a86 <myproc>:
myproc(void) {
    80001a86:	1101                	addi	sp,sp,-32
    80001a88:	ec06                	sd	ra,24(sp)
    80001a8a:	e822                	sd	s0,16(sp)
    80001a8c:	e426                	sd	s1,8(sp)
    80001a8e:	1000                	addi	s0,sp,32
  push_off();
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	0fa080e7          	jalr	250(ra) # 80000b8a <push_off>
    80001a98:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a9a:	2781                	sext.w	a5,a5
    80001a9c:	079e                	slli	a5,a5,0x7
    80001a9e:	00010717          	auipc	a4,0x10
    80001aa2:	80270713          	addi	a4,a4,-2046 # 800112a0 <pid_lock>
    80001aa6:	97ba                	add	a5,a5,a4
    80001aa8:	6f84                	ld	s1,24(a5)
  pop_off();
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	180080e7          	jalr	384(ra) # 80000c2a <pop_off>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret

0000000080001abe <forkret>:
{
    80001abe:	1141                	addi	sp,sp,-16
    80001ac0:	e406                	sd	ra,8(sp)
    80001ac2:	e022                	sd	s0,0(sp)
    80001ac4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001ac6:	00000097          	auipc	ra,0x0
    80001aca:	fc0080e7          	jalr	-64(ra) # 80001a86 <myproc>
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	1bc080e7          	jalr	444(ra) # 80000c8a <release>
  if (first) {
    80001ad6:	00007797          	auipc	a5,0x7
    80001ada:	e2a7a783          	lw	a5,-470(a5) # 80008900 <first.1691>
    80001ade:	eb89                	bnez	a5,80001af0 <forkret+0x32>
  usertrapret();
    80001ae0:	00001097          	auipc	ra,0x1
    80001ae4:	cd0080e7          	jalr	-816(ra) # 800027b0 <usertrapret>
}
    80001ae8:	60a2                	ld	ra,8(sp)
    80001aea:	6402                	ld	s0,0(sp)
    80001aec:	0141                	addi	sp,sp,16
    80001aee:	8082                	ret
    first = 0;
    80001af0:	00007797          	auipc	a5,0x7
    80001af4:	e007a823          	sw	zero,-496(a5) # 80008900 <first.1691>
    fsinit(ROOTDEV);
    80001af8:	4505                	li	a0,1
    80001afa:	00002097          	auipc	ra,0x2
    80001afe:	b78080e7          	jalr	-1160(ra) # 80003672 <fsinit>
    80001b02:	bff9                	j	80001ae0 <forkret+0x22>

0000000080001b04 <allocpid>:
allocpid() {
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b10:	0000f917          	auipc	s2,0xf
    80001b14:	79090913          	addi	s2,s2,1936 # 800112a0 <pid_lock>
    80001b18:	854a                	mv	a0,s2
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	0bc080e7          	jalr	188(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b22:	00007797          	auipc	a5,0x7
    80001b26:	de278793          	addi	a5,a5,-542 # 80008904 <nextpid>
    80001b2a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b2c:	0014871b          	addiw	a4,s1,1
    80001b30:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b32:	854a                	mv	a0,s2
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	156080e7          	jalr	342(ra) # 80000c8a <release>
}
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	60e2                	ld	ra,24(sp)
    80001b40:	6442                	ld	s0,16(sp)
    80001b42:	64a2                	ld	s1,8(sp)
    80001b44:	6902                	ld	s2,0(sp)
    80001b46:	6105                	addi	sp,sp,32
    80001b48:	8082                	ret

0000000080001b4a <proc_pagetable>:
{
    80001b4a:	1101                	addi	sp,sp,-32
    80001b4c:	ec06                	sd	ra,24(sp)
    80001b4e:	e822                	sd	s0,16(sp)
    80001b50:	e426                	sd	s1,8(sp)
    80001b52:	e04a                	sd	s2,0(sp)
    80001b54:	1000                	addi	s0,sp,32
    80001b56:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	7b8080e7          	jalr	1976(ra) # 80001310 <uvmcreate>
    80001b60:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b62:	c121                	beqz	a0,80001ba2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b64:	4729                	li	a4,10
    80001b66:	00005697          	auipc	a3,0x5
    80001b6a:	49a68693          	addi	a3,a3,1178 # 80007000 <_trampoline>
    80001b6e:	6605                	lui	a2,0x1
    80001b70:	040005b7          	lui	a1,0x4000
    80001b74:	15fd                	addi	a1,a1,-1
    80001b76:	05b2                	slli	a1,a1,0xc
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	52e080e7          	jalr	1326(ra) # 800010a6 <mappages>
    80001b80:	02054863          	bltz	a0,80001bb0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b84:	4719                	li	a4,6
    80001b86:	05893683          	ld	a3,88(s2)
    80001b8a:	6605                	lui	a2,0x1
    80001b8c:	020005b7          	lui	a1,0x2000
    80001b90:	15fd                	addi	a1,a1,-1
    80001b92:	05b6                	slli	a1,a1,0xd
    80001b94:	8526                	mv	a0,s1
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	510080e7          	jalr	1296(ra) # 800010a6 <mappages>
    80001b9e:	02054163          	bltz	a0,80001bc0 <proc_pagetable+0x76>
}
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6902                	ld	s2,0(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret
    uvmfree(pagetable, 0);
    80001bb0:	4581                	li	a1,0
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	958080e7          	jalr	-1704(ra) # 8000150c <uvmfree>
    return 0;
    80001bbc:	4481                	li	s1,0
    80001bbe:	b7d5                	j	80001ba2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc0:	4681                	li	a3,0
    80001bc2:	4605                	li	a2,1
    80001bc4:	040005b7          	lui	a1,0x4000
    80001bc8:	15fd                	addi	a1,a1,-1
    80001bca:	05b2                	slli	a1,a1,0xc
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	68c080e7          	jalr	1676(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001bd6:	4581                	li	a1,0
    80001bd8:	8526                	mv	a0,s1
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	932080e7          	jalr	-1742(ra) # 8000150c <uvmfree>
    return 0;
    80001be2:	4481                	li	s1,0
    80001be4:	bf7d                	j	80001ba2 <proc_pagetable+0x58>

0000000080001be6 <proc_freepagetable>:
{
    80001be6:	1101                	addi	sp,sp,-32
    80001be8:	ec06                	sd	ra,24(sp)
    80001bea:	e822                	sd	s0,16(sp)
    80001bec:	e426                	sd	s1,8(sp)
    80001bee:	e04a                	sd	s2,0(sp)
    80001bf0:	1000                	addi	s0,sp,32
    80001bf2:	84aa                	mv	s1,a0
    80001bf4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf6:	4681                	li	a3,0
    80001bf8:	4605                	li	a2,1
    80001bfa:	040005b7          	lui	a1,0x4000
    80001bfe:	15fd                	addi	a1,a1,-1
    80001c00:	05b2                	slli	a1,a1,0xc
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	658080e7          	jalr	1624(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c0a:	4681                	li	a3,0
    80001c0c:	4605                	li	a2,1
    80001c0e:	020005b7          	lui	a1,0x2000
    80001c12:	15fd                	addi	a1,a1,-1
    80001c14:	05b6                	slli	a1,a1,0xd
    80001c16:	8526                	mv	a0,s1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	642080e7          	jalr	1602(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001c20:	85ca                	mv	a1,s2
    80001c22:	8526                	mv	a0,s1
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	8e8080e7          	jalr	-1816(ra) # 8000150c <uvmfree>
}
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6902                	ld	s2,0(sp)
    80001c34:	6105                	addi	sp,sp,32
    80001c36:	8082                	ret

0000000080001c38 <freeproc>:
{
    80001c38:	1101                	addi	sp,sp,-32
    80001c3a:	ec06                	sd	ra,24(sp)
    80001c3c:	e822                	sd	s0,16(sp)
    80001c3e:	e426                	sd	s1,8(sp)
    80001c40:	1000                	addi	s0,sp,32
    80001c42:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c44:	6d28                	ld	a0,88(a0)
    80001c46:	c509                	beqz	a0,80001c50 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	da2080e7          	jalr	-606(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001c50:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c54:	68a8                	ld	a0,80(s1)
    80001c56:	c511                	beqz	a0,80001c62 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c58:	64ac                	ld	a1,72(s1)
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f8c080e7          	jalr	-116(ra) # 80001be6 <proc_freepagetable>
  p->pagetable = 0;
    80001c62:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c66:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c6a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c6e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c72:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c76:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c7a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c7e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c82:	0004ac23          	sw	zero,24(s1)
}
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6105                	addi	sp,sp,32
    80001c8e:	8082                	ret

0000000080001c90 <allocproc>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	e04a                	sd	s2,0(sp)
    80001c9a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9c:	00010497          	auipc	s1,0x10
    80001ca0:	a1c48493          	addi	s1,s1,-1508 # 800116b8 <proc>
    80001ca4:	00021917          	auipc	s2,0x21
    80001ca8:	41490913          	addi	s2,s2,1044 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	f28080e7          	jalr	-216(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001cb6:	4c9c                	lw	a5,24(s1)
    80001cb8:	cf81                	beqz	a5,80001cd0 <allocproc+0x40>
      release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	fce080e7          	jalr	-50(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc4:	46848493          	addi	s1,s1,1128
    80001cc8:	ff2492e3          	bne	s1,s2,80001cac <allocproc+0x1c>
  return 0;
    80001ccc:	4481                	li	s1,0
    80001cce:	a0b9                	j	80001d1c <allocproc+0x8c>
  p->pid = allocpid();
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	e34080e7          	jalr	-460(ra) # 80001b04 <allocpid>
    80001cd8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	e0c080e7          	jalr	-500(ra) # 80000ae6 <kalloc>
    80001ce2:	892a                	mv	s2,a0
    80001ce4:	eca8                	sd	a0,88(s1)
    80001ce6:	c131                	beqz	a0,80001d2a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	e60080e7          	jalr	-416(ra) # 80001b4a <proc_pagetable>
    80001cf2:	892a                	mv	s2,a0
    80001cf4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cf6:	c129                	beqz	a0,80001d38 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001cf8:	07000613          	li	a2,112
    80001cfc:	4581                	li	a1,0
    80001cfe:	06048513          	addi	a0,s1,96
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	fd0080e7          	jalr	-48(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d0a:	00000797          	auipc	a5,0x0
    80001d0e:	db478793          	addi	a5,a5,-588 # 80001abe <forkret>
    80001d12:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d14:	60bc                	ld	a5,64(s1)
    80001d16:	6705                	lui	a4,0x1
    80001d18:	97ba                	add	a5,a5,a4
    80001d1a:	f4bc                	sd	a5,104(s1)
}
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6902                	ld	s2,0(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret
    release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f5e080e7          	jalr	-162(ra) # 80000c8a <release>
    return 0;
    80001d34:	84ca                	mv	s1,s2
    80001d36:	b7dd                	j	80001d1c <allocproc+0x8c>
    freeproc(p);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	efe080e7          	jalr	-258(ra) # 80001c38 <freeproc>
    release(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f46080e7          	jalr	-186(ra) # 80000c8a <release>
    return 0;
    80001d4c:	84ca                	mv	s1,s2
    80001d4e:	b7f9                	j	80001d1c <allocproc+0x8c>

0000000080001d50 <userinit>:
{
    80001d50:	1101                	addi	sp,sp,-32
    80001d52:	ec06                	sd	ra,24(sp)
    80001d54:	e822                	sd	s0,16(sp)
    80001d56:	e426                	sd	s1,8(sp)
    80001d58:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	f36080e7          	jalr	-202(ra) # 80001c90 <allocproc>
    80001d62:	84aa                	mv	s1,a0
  initproc = p;
    80001d64:	00007797          	auipc	a5,0x7
    80001d68:	2ca7b223          	sd	a0,708(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d6c:	03400613          	li	a2,52
    80001d70:	00007597          	auipc	a1,0x7
    80001d74:	ba058593          	addi	a1,a1,-1120 # 80008910 <initcode>
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	5c4080e7          	jalr	1476(ra) # 8000133e <uvminit>
  p->sz = PGSIZE;
    80001d82:	6785                	lui	a5,0x1
    80001d84:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d86:	6cb8                	ld	a4,88(s1)
    80001d88:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d8c:	6cb8                	ld	a4,88(s1)
    80001d8e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d90:	4641                	li	a2,16
    80001d92:	00006597          	auipc	a1,0x6
    80001d96:	49e58593          	addi	a1,a1,1182 # 80008230 <indent.1667+0x40>
    80001d9a:	15848513          	addi	a0,s1,344
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	08a080e7          	jalr	138(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001da6:	00006517          	auipc	a0,0x6
    80001daa:	49a50513          	addi	a0,a0,1178 # 80008240 <indent.1667+0x50>
    80001dae:	00002097          	auipc	ra,0x2
    80001db2:	308080e7          	jalr	776(ra) # 800040b6 <namei>
    80001db6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dba:	4789                	li	a5,2
    80001dbc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	eca080e7          	jalr	-310(ra) # 80000c8a <release>
}
    80001dc8:	60e2                	ld	ra,24(sp)
    80001dca:	6442                	ld	s0,16(sp)
    80001dcc:	64a2                	ld	s1,8(sp)
    80001dce:	6105                	addi	sp,sp,32
    80001dd0:	8082                	ret

0000000080001dd2 <growproc>:
{
    80001dd2:	1101                	addi	sp,sp,-32
    80001dd4:	ec06                	sd	ra,24(sp)
    80001dd6:	e822                	sd	s0,16(sp)
    80001dd8:	e426                	sd	s1,8(sp)
    80001dda:	e04a                	sd	s2,0(sp)
    80001ddc:	1000                	addi	s0,sp,32
    80001dde:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	ca6080e7          	jalr	-858(ra) # 80001a86 <myproc>
    80001de8:	892a                	mv	s2,a0
  sz = p->sz;
    80001dea:	652c                	ld	a1,72(a0)
    80001dec:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001df0:	00904f63          	bgtz	s1,80001e0e <growproc+0x3c>
  } else if(n < 0){
    80001df4:	0204cc63          	bltz	s1,80001e2c <growproc+0x5a>
  p->sz = sz;
    80001df8:	1602                	slli	a2,a2,0x20
    80001dfa:	9201                	srli	a2,a2,0x20
    80001dfc:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e00:	4501                	li	a0,0
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e0e:	9e25                	addw	a2,a2,s1
    80001e10:	1602                	slli	a2,a2,0x20
    80001e12:	9201                	srli	a2,a2,0x20
    80001e14:	1582                	slli	a1,a1,0x20
    80001e16:	9181                	srli	a1,a1,0x20
    80001e18:	6928                	ld	a0,80(a0)
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	5de080e7          	jalr	1502(ra) # 800013f8 <uvmalloc>
    80001e22:	0005061b          	sext.w	a2,a0
    80001e26:	fa69                	bnez	a2,80001df8 <growproc+0x26>
      return -1;
    80001e28:	557d                	li	a0,-1
    80001e2a:	bfe1                	j	80001e02 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e2c:	9e25                	addw	a2,a2,s1
    80001e2e:	1602                	slli	a2,a2,0x20
    80001e30:	9201                	srli	a2,a2,0x20
    80001e32:	1582                	slli	a1,a1,0x20
    80001e34:	9181                	srli	a1,a1,0x20
    80001e36:	6928                	ld	a0,80(a0)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	578080e7          	jalr	1400(ra) # 800013b0 <uvmdealloc>
    80001e40:	0005061b          	sext.w	a2,a0
    80001e44:	bf55                	j	80001df8 <growproc+0x26>

0000000080001e46 <fork>:
{
    80001e46:	7139                	addi	sp,sp,-64
    80001e48:	fc06                	sd	ra,56(sp)
    80001e4a:	f822                	sd	s0,48(sp)
    80001e4c:	f426                	sd	s1,40(sp)
    80001e4e:	f04a                	sd	s2,32(sp)
    80001e50:	ec4e                	sd	s3,24(sp)
    80001e52:	e852                	sd	s4,16(sp)
    80001e54:	e456                	sd	s5,8(sp)
    80001e56:	e05a                	sd	s6,0(sp)
    80001e58:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	c2c080e7          	jalr	-980(ra) # 80001a86 <myproc>
    80001e62:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	e2c080e7          	jalr	-468(ra) # 80001c90 <allocproc>
    80001e6c:	12050e63          	beqz	a0,80001fa8 <fork+0x162>
    80001e70:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e72:	0489b603          	ld	a2,72(s3)
    80001e76:	692c                	ld	a1,80(a0)
    80001e78:	0509b503          	ld	a0,80(s3)
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	6c8080e7          	jalr	1736(ra) # 80001544 <uvmcopy>
    80001e84:	04054863          	bltz	a0,80001ed4 <fork+0x8e>
  np->sz = p->sz;
    80001e88:	0489b783          	ld	a5,72(s3)
    80001e8c:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e90:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e94:	0589b683          	ld	a3,88(s3)
    80001e98:	87b6                	mv	a5,a3
    80001e9a:	058a3703          	ld	a4,88(s4)
    80001e9e:	12068693          	addi	a3,a3,288
    80001ea2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ea6:	6788                	ld	a0,8(a5)
    80001ea8:	6b8c                	ld	a1,16(a5)
    80001eaa:	6f90                	ld	a2,24(a5)
    80001eac:	01073023          	sd	a6,0(a4)
    80001eb0:	e708                	sd	a0,8(a4)
    80001eb2:	eb0c                	sd	a1,16(a4)
    80001eb4:	ef10                	sd	a2,24(a4)
    80001eb6:	02078793          	addi	a5,a5,32
    80001eba:	02070713          	addi	a4,a4,32
    80001ebe:	fed792e3          	bne	a5,a3,80001ea2 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001ec2:	058a3783          	ld	a5,88(s4)
    80001ec6:	0607b823          	sd	zero,112(a5)
    80001eca:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ece:	15000913          	li	s2,336
    80001ed2:	a03d                	j	80001f00 <fork+0xba>
    freeproc(np);
    80001ed4:	8552                	mv	a0,s4
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	d62080e7          	jalr	-670(ra) # 80001c38 <freeproc>
    release(&np->lock);
    80001ede:	8552                	mv	a0,s4
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	daa080e7          	jalr	-598(ra) # 80000c8a <release>
    return -1;
    80001ee8:	5b7d                	li	s6,-1
    80001eea:	a065                	j	80001f92 <fork+0x14c>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eec:	00003097          	auipc	ra,0x3
    80001ef0:	868080e7          	jalr	-1944(ra) # 80004754 <filedup>
    80001ef4:	009a07b3          	add	a5,s4,s1
    80001ef8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001efa:	04a1                	addi	s1,s1,8
    80001efc:	01248763          	beq	s1,s2,80001f0a <fork+0xc4>
    if(p->ofile[i])
    80001f00:	009987b3          	add	a5,s3,s1
    80001f04:	6388                	ld	a0,0(a5)
    80001f06:	f17d                	bnez	a0,80001eec <fork+0xa6>
    80001f08:	bfcd                	j	80001efa <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001f0a:	1509b503          	ld	a0,336(s3)
    80001f0e:	00002097          	auipc	ra,0x2
    80001f12:	99e080e7          	jalr	-1634(ra) # 800038ac <idup>
    80001f16:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f1a:	4641                	li	a2,16
    80001f1c:	15898593          	addi	a1,s3,344
    80001f20:	158a0513          	addi	a0,s4,344
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	f04080e7          	jalr	-252(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001f2c:	038a2b03          	lw	s6,56(s4)
  np->state = RUNNABLE;
    80001f30:	4789                	li	a5,2
    80001f32:	00fa2c23          	sw	a5,24(s4)
  for(int i = 0;i<VMASIZE;++i){
    80001f36:	16898493          	addi	s1,s3,360
    80001f3a:	168a0913          	addi	s2,s4,360
    80001f3e:	46898993          	addi	s3,s3,1128
    if(p->vma[i].valid == 1){
    80001f42:	4a85                	li	s5,1
    80001f44:	a835                	j	80001f80 <fork+0x13a>
      np->vma[i] = p->vma[i];
    80001f46:	6088                	ld	a0,0(s1)
    80001f48:	648c                	ld	a1,8(s1)
    80001f4a:	6890                	ld	a2,16(s1)
    80001f4c:	6c94                	ld	a3,24(s1)
    80001f4e:	7098                	ld	a4,32(s1)
    80001f50:	749c                	ld	a5,40(s1)
    80001f52:	00a93023          	sd	a0,0(s2)
    80001f56:	00b93423          	sd	a1,8(s2)
    80001f5a:	00c93823          	sd	a2,16(s2)
    80001f5e:	00d93c23          	sd	a3,24(s2)
    80001f62:	02e93023          	sd	a4,32(s2)
    80001f66:	02f93423          	sd	a5,40(s2)
      filedup(p->vma[i].f);
    80001f6a:	7088                	ld	a0,32(s1)
    80001f6c:	00002097          	auipc	ra,0x2
    80001f70:	7e8080e7          	jalr	2024(ra) # 80004754 <filedup>
  for(int i = 0;i<VMASIZE;++i){
    80001f74:	03048493          	addi	s1,s1,48
    80001f78:	03090913          	addi	s2,s2,48
    80001f7c:	01348663          	beq	s1,s3,80001f88 <fork+0x142>
    if(p->vma[i].valid == 1){
    80001f80:	549c                	lw	a5,40(s1)
    80001f82:	ff5799e3          	bne	a5,s5,80001f74 <fork+0x12e>
    80001f86:	b7c1                	j	80001f46 <fork+0x100>
  release(&np->lock);
    80001f88:	8552                	mv	a0,s4
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d00080e7          	jalr	-768(ra) # 80000c8a <release>
}
    80001f92:	855a                	mv	a0,s6
    80001f94:	70e2                	ld	ra,56(sp)
    80001f96:	7442                	ld	s0,48(sp)
    80001f98:	74a2                	ld	s1,40(sp)
    80001f9a:	7902                	ld	s2,32(sp)
    80001f9c:	69e2                	ld	s3,24(sp)
    80001f9e:	6a42                	ld	s4,16(sp)
    80001fa0:	6aa2                	ld	s5,8(sp)
    80001fa2:	6b02                	ld	s6,0(sp)
    80001fa4:	6121                	addi	sp,sp,64
    80001fa6:	8082                	ret
    return -1;
    80001fa8:	5b7d                	li	s6,-1
    80001faa:	b7e5                	j	80001f92 <fork+0x14c>

0000000080001fac <reparent>:
{
    80001fac:	7179                	addi	sp,sp,-48
    80001fae:	f406                	sd	ra,40(sp)
    80001fb0:	f022                	sd	s0,32(sp)
    80001fb2:	ec26                	sd	s1,24(sp)
    80001fb4:	e84a                	sd	s2,16(sp)
    80001fb6:	e44e                	sd	s3,8(sp)
    80001fb8:	e052                	sd	s4,0(sp)
    80001fba:	1800                	addi	s0,sp,48
    80001fbc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fbe:	0000f497          	auipc	s1,0xf
    80001fc2:	6fa48493          	addi	s1,s1,1786 # 800116b8 <proc>
      pp->parent = initproc;
    80001fc6:	00007a17          	auipc	s4,0x7
    80001fca:	062a0a13          	addi	s4,s4,98 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fce:	00021997          	auipc	s3,0x21
    80001fd2:	0ea98993          	addi	s3,s3,234 # 800230b8 <tickslock>
    80001fd6:	a029                	j	80001fe0 <reparent+0x34>
    80001fd8:	46848493          	addi	s1,s1,1128
    80001fdc:	03348363          	beq	s1,s3,80002002 <reparent+0x56>
    if(pp->parent == p){
    80001fe0:	709c                	ld	a5,32(s1)
    80001fe2:	ff279be3          	bne	a5,s2,80001fd8 <reparent+0x2c>
      acquire(&pp->lock);
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	bee080e7          	jalr	-1042(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001ff0:	000a3783          	ld	a5,0(s4)
    80001ff4:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	c92080e7          	jalr	-878(ra) # 80000c8a <release>
    80002000:	bfe1                	j	80001fd8 <reparent+0x2c>
}
    80002002:	70a2                	ld	ra,40(sp)
    80002004:	7402                	ld	s0,32(sp)
    80002006:	64e2                	ld	s1,24(sp)
    80002008:	6942                	ld	s2,16(sp)
    8000200a:	69a2                	ld	s3,8(sp)
    8000200c:	6a02                	ld	s4,0(sp)
    8000200e:	6145                	addi	sp,sp,48
    80002010:	8082                	ret

0000000080002012 <scheduler>:
{
    80002012:	711d                	addi	sp,sp,-96
    80002014:	ec86                	sd	ra,88(sp)
    80002016:	e8a2                	sd	s0,80(sp)
    80002018:	e4a6                	sd	s1,72(sp)
    8000201a:	e0ca                	sd	s2,64(sp)
    8000201c:	fc4e                	sd	s3,56(sp)
    8000201e:	f852                	sd	s4,48(sp)
    80002020:	f456                	sd	s5,40(sp)
    80002022:	f05a                	sd	s6,32(sp)
    80002024:	ec5e                	sd	s7,24(sp)
    80002026:	e862                	sd	s8,16(sp)
    80002028:	e466                	sd	s9,8(sp)
    8000202a:	1080                	addi	s0,sp,96
    8000202c:	8792                	mv	a5,tp
  int id = r_tp();
    8000202e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002030:	00779c13          	slli	s8,a5,0x7
    80002034:	0000f717          	auipc	a4,0xf
    80002038:	26c70713          	addi	a4,a4,620 # 800112a0 <pid_lock>
    8000203c:	9762                	add	a4,a4,s8
    8000203e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002042:	0000f717          	auipc	a4,0xf
    80002046:	27e70713          	addi	a4,a4,638 # 800112c0 <cpus+0x8>
    8000204a:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    8000204c:	4a89                	li	s5,2
        c->proc = p;
    8000204e:	079e                	slli	a5,a5,0x7
    80002050:	0000fb17          	auipc	s6,0xf
    80002054:	250b0b13          	addi	s6,s6,592 # 800112a0 <pid_lock>
    80002058:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000205a:	00021a17          	auipc	s4,0x21
    8000205e:	05ea0a13          	addi	s4,s4,94 # 800230b8 <tickslock>
    int nproc = 0;
    80002062:	4c81                	li	s9,0
    80002064:	a8a1                	j	800020bc <scheduler+0xaa>
        p->state = RUNNING;
    80002066:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000206a:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000206e:	06048593          	addi	a1,s1,96
    80002072:	8562                	mv	a0,s8
    80002074:	00000097          	auipc	ra,0x0
    80002078:	692080e7          	jalr	1682(ra) # 80002706 <swtch>
        c->proc = 0;
    8000207c:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000208a:	46848493          	addi	s1,s1,1128
    8000208e:	01448d63          	beq	s1,s4,800020a8 <scheduler+0x96>
      acquire(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b42080e7          	jalr	-1214(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    8000209c:	4c9c                	lw	a5,24(s1)
    8000209e:	d3ed                	beqz	a5,80002080 <scheduler+0x6e>
        nproc++;
    800020a0:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800020a2:	fd579fe3          	bne	a5,s5,80002080 <scheduler+0x6e>
    800020a6:	b7c1                	j	80002066 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800020a8:	013aca63          	blt	s5,s3,800020bc <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b4:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020b8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c4:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020c8:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800020ca:	0000f497          	auipc	s1,0xf
    800020ce:	5ee48493          	addi	s1,s1,1518 # 800116b8 <proc>
        p->state = RUNNING;
    800020d2:	4b8d                	li	s7,3
    800020d4:	bf7d                	j	80002092 <scheduler+0x80>

00000000800020d6 <sched>:
{
    800020d6:	7179                	addi	sp,sp,-48
    800020d8:	f406                	sd	ra,40(sp)
    800020da:	f022                	sd	s0,32(sp)
    800020dc:	ec26                	sd	s1,24(sp)
    800020de:	e84a                	sd	s2,16(sp)
    800020e0:	e44e                	sd	s3,8(sp)
    800020e2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	9a2080e7          	jalr	-1630(ra) # 80001a86 <myproc>
    800020ec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	a6e080e7          	jalr	-1426(ra) # 80000b5c <holding>
    800020f6:	c93d                	beqz	a0,8000216c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020f8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020fa:	2781                	sext.w	a5,a5
    800020fc:	079e                	slli	a5,a5,0x7
    800020fe:	0000f717          	auipc	a4,0xf
    80002102:	1a270713          	addi	a4,a4,418 # 800112a0 <pid_lock>
    80002106:	97ba                	add	a5,a5,a4
    80002108:	0907a703          	lw	a4,144(a5)
    8000210c:	4785                	li	a5,1
    8000210e:	06f71763          	bne	a4,a5,8000217c <sched+0xa6>
  if(p->state == RUNNING)
    80002112:	4c98                	lw	a4,24(s1)
    80002114:	478d                	li	a5,3
    80002116:	06f70b63          	beq	a4,a5,8000218c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000211a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000211e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002120:	efb5                	bnez	a5,8000219c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002122:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002124:	0000f917          	auipc	s2,0xf
    80002128:	17c90913          	addi	s2,s2,380 # 800112a0 <pid_lock>
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	97ca                	add	a5,a5,s2
    80002132:	0947a983          	lw	s3,148(a5)
    80002136:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002138:	2781                	sext.w	a5,a5
    8000213a:	079e                	slli	a5,a5,0x7
    8000213c:	0000f597          	auipc	a1,0xf
    80002140:	18458593          	addi	a1,a1,388 # 800112c0 <cpus+0x8>
    80002144:	95be                	add	a1,a1,a5
    80002146:	06048513          	addi	a0,s1,96
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	5bc080e7          	jalr	1468(ra) # 80002706 <swtch>
    80002152:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002154:	2781                	sext.w	a5,a5
    80002156:	079e                	slli	a5,a5,0x7
    80002158:	97ca                	add	a5,a5,s2
    8000215a:	0937aa23          	sw	s3,148(a5)
}
    8000215e:	70a2                	ld	ra,40(sp)
    80002160:	7402                	ld	s0,32(sp)
    80002162:	64e2                	ld	s1,24(sp)
    80002164:	6942                	ld	s2,16(sp)
    80002166:	69a2                	ld	s3,8(sp)
    80002168:	6145                	addi	sp,sp,48
    8000216a:	8082                	ret
    panic("sched p->lock");
    8000216c:	00006517          	auipc	a0,0x6
    80002170:	0dc50513          	addi	a0,a0,220 # 80008248 <indent.1667+0x58>
    80002174:	ffffe097          	auipc	ra,0xffffe
    80002178:	3bc080e7          	jalr	956(ra) # 80000530 <panic>
    panic("sched locks");
    8000217c:	00006517          	auipc	a0,0x6
    80002180:	0dc50513          	addi	a0,a0,220 # 80008258 <indent.1667+0x68>
    80002184:	ffffe097          	auipc	ra,0xffffe
    80002188:	3ac080e7          	jalr	940(ra) # 80000530 <panic>
    panic("sched running");
    8000218c:	00006517          	auipc	a0,0x6
    80002190:	0dc50513          	addi	a0,a0,220 # 80008268 <indent.1667+0x78>
    80002194:	ffffe097          	auipc	ra,0xffffe
    80002198:	39c080e7          	jalr	924(ra) # 80000530 <panic>
    panic("sched interruptible");
    8000219c:	00006517          	auipc	a0,0x6
    800021a0:	0dc50513          	addi	a0,a0,220 # 80008278 <indent.1667+0x88>
    800021a4:	ffffe097          	auipc	ra,0xffffe
    800021a8:	38c080e7          	jalr	908(ra) # 80000530 <panic>

00000000800021ac <exit>:
{
    800021ac:	7139                	addi	sp,sp,-64
    800021ae:	fc06                	sd	ra,56(sp)
    800021b0:	f822                	sd	s0,48(sp)
    800021b2:	f426                	sd	s1,40(sp)
    800021b4:	f04a                	sd	s2,32(sp)
    800021b6:	ec4e                	sd	s3,24(sp)
    800021b8:	e852                	sd	s4,16(sp)
    800021ba:	e456                	sd	s5,8(sp)
    800021bc:	0080                	addi	s0,sp,64
    800021be:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	8c6080e7          	jalr	-1850(ra) # 80001a86 <myproc>
    800021c8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ca:	00007797          	auipc	a5,0x7
    800021ce:	e5e7b783          	ld	a5,-418(a5) # 80009028 <initproc>
    800021d2:	0d050493          	addi	s1,a0,208
    800021d6:	15050913          	addi	s2,a0,336
    800021da:	02a79363          	bne	a5,a0,80002200 <exit+0x54>
    panic("init exiting");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	0b250513          	addi	a0,a0,178 # 80008290 <indent.1667+0xa0>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	34a080e7          	jalr	842(ra) # 80000530 <panic>
      fileclose(f);
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	5b8080e7          	jalr	1464(ra) # 800047a6 <fileclose>
      p->ofile[fd] = 0;
    800021f6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021fa:	04a1                	addi	s1,s1,8
    800021fc:	01248563          	beq	s1,s2,80002206 <exit+0x5a>
    if(p->ofile[fd]){
    80002200:	6088                	ld	a0,0(s1)
    80002202:	f575                	bnez	a0,800021ee <exit+0x42>
    80002204:	bfdd                	j	800021fa <exit+0x4e>
    80002206:	16898493          	addi	s1,s3,360
    8000220a:	46898a13          	addi	s4,s3,1128
    8000220e:	a081                	j	8000224e <exit+0xa2>
        filewrite(p->vma[i].f, p->vma[i].address, p->vma[i].length);
    80002210:	4490                	lw	a2,8(s1)
    80002212:	608c                	ld	a1,0(s1)
    80002214:	7088                	ld	a0,32(s1)
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	78c080e7          	jalr	1932(ra) # 800049a2 <filewrite>
      fileclose(p->vma[i].f);
    8000221e:	02093503          	ld	a0,32(s2)
    80002222:	00002097          	auipc	ra,0x2
    80002226:	584080e7          	jalr	1412(ra) # 800047a6 <fileclose>
      uvmunmap(p->pagetable, p->vma[i].address, p->vma[i].length / PGSIZE, 1);
    8000222a:	00893603          	ld	a2,8(s2)
    8000222e:	4685                	li	a3,1
    80002230:	8231                	srli	a2,a2,0xc
    80002232:	00093583          	ld	a1,0(s2)
    80002236:	0509b503          	ld	a0,80(s3)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	020080e7          	jalr	32(ra) # 8000125a <uvmunmap>
      p->vma[i].valid = 0;
    80002242:	02092423          	sw	zero,40(s2)
  for (int i = 0; i < VMASIZE; i++) {
    80002246:	03048493          	addi	s1,s1,48
    8000224a:	01448963          	beq	s1,s4,8000225c <exit+0xb0>
    if (p->vma[i].valid) {
    8000224e:	8926                	mv	s2,s1
    80002250:	549c                	lw	a5,40(s1)
    80002252:	dbf5                	beqz	a5,80002246 <exit+0x9a>
      if (p->vma[i].flags & MAP_SHARED) {
    80002254:	48dc                	lw	a5,20(s1)
    80002256:	8b85                	andi	a5,a5,1
    80002258:	d3f9                	beqz	a5,8000221e <exit+0x72>
    8000225a:	bf5d                	j	80002210 <exit+0x64>
  begin_op();
    8000225c:	00002097          	auipc	ra,0x2
    80002260:	076080e7          	jalr	118(ra) # 800042d2 <begin_op>
  iput(p->cwd);
    80002264:	1509b503          	ld	a0,336(s3)
    80002268:	00002097          	auipc	ra,0x2
    8000226c:	852080e7          	jalr	-1966(ra) # 80003aba <iput>
  end_op();
    80002270:	00002097          	auipc	ra,0x2
    80002274:	0e2080e7          	jalr	226(ra) # 80004352 <end_op>
  p->cwd = 0;
    80002278:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000227c:	00007497          	auipc	s1,0x7
    80002280:	dac48493          	addi	s1,s1,-596 # 80009028 <initproc>
    80002284:	6088                	ld	a0,0(s1)
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	950080e7          	jalr	-1712(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    8000228e:	6088                	ld	a0,0(s1)
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	658080e7          	jalr	1624(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    80002298:	6088                	ld	a0,0(s1)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9f0080e7          	jalr	-1552(ra) # 80000c8a <release>
  acquire(&p->lock);
    800022a2:	854e                	mv	a0,s3
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	932080e7          	jalr	-1742(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    800022ac:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800022b0:	854e                	mv	a0,s3
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	91a080e7          	jalr	-1766(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    800022c4:	854e                	mv	a0,s3
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>
  reparent(p);
    800022ce:	854e                	mv	a0,s3
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	cdc080e7          	jalr	-804(ra) # 80001fac <reparent>
  wakeup1(original_parent);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	60e080e7          	jalr	1550(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800022e2:	0359aa23          	sw	s5,52(s3)
  p->state = ZOMBIE;
    800022e6:	4791                	li	a5,4
    800022e8:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	99c080e7          	jalr	-1636(ra) # 80000c8a <release>
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	de0080e7          	jalr	-544(ra) # 800020d6 <sched>
  panic("zombie exit");
    800022fe:	00006517          	auipc	a0,0x6
    80002302:	fa250513          	addi	a0,a0,-94 # 800082a0 <indent.1667+0xb0>
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	22a080e7          	jalr	554(ra) # 80000530 <panic>

000000008000230e <yield>:
{
    8000230e:	1101                	addi	sp,sp,-32
    80002310:	ec06                	sd	ra,24(sp)
    80002312:	e822                	sd	s0,16(sp)
    80002314:	e426                	sd	s1,8(sp)
    80002316:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	76e080e7          	jalr	1902(ra) # 80001a86 <myproc>
    80002320:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	8b4080e7          	jalr	-1868(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000232a:	4789                	li	a5,2
    8000232c:	cc9c                	sw	a5,24(s1)
  sched();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	da8080e7          	jalr	-600(ra) # 800020d6 <sched>
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
}
    80002340:	60e2                	ld	ra,24(sp)
    80002342:	6442                	ld	s0,16(sp)
    80002344:	64a2                	ld	s1,8(sp)
    80002346:	6105                	addi	sp,sp,32
    80002348:	8082                	ret

000000008000234a <sleep>:
{
    8000234a:	7179                	addi	sp,sp,-48
    8000234c:	f406                	sd	ra,40(sp)
    8000234e:	f022                	sd	s0,32(sp)
    80002350:	ec26                	sd	s1,24(sp)
    80002352:	e84a                	sd	s2,16(sp)
    80002354:	e44e                	sd	s3,8(sp)
    80002356:	1800                	addi	s0,sp,48
    80002358:	89aa                	mv	s3,a0
    8000235a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	72a080e7          	jalr	1834(ra) # 80001a86 <myproc>
    80002364:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002366:	05250663          	beq	a0,s2,800023b2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	86c080e7          	jalr	-1940(ra) # 80000bd6 <acquire>
    release(lk);
    80002372:	854a                	mv	a0,s2
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
  p->chan = chan;
    8000237c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002380:	4785                	li	a5,1
    80002382:	cc9c                	sw	a5,24(s1)
  sched();
    80002384:	00000097          	auipc	ra,0x0
    80002388:	d52080e7          	jalr	-686(ra) # 800020d6 <sched>
  p->chan = 0;
    8000238c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	8f8080e7          	jalr	-1800(ra) # 80000c8a <release>
    acquire(lk);
    8000239a:	854a                	mv	a0,s2
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
}
    800023a4:	70a2                	ld	ra,40(sp)
    800023a6:	7402                	ld	s0,32(sp)
    800023a8:	64e2                	ld	s1,24(sp)
    800023aa:	6942                	ld	s2,16(sp)
    800023ac:	69a2                	ld	s3,8(sp)
    800023ae:	6145                	addi	sp,sp,48
    800023b0:	8082                	ret
  p->chan = chan;
    800023b2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800023b6:	4785                	li	a5,1
    800023b8:	cd1c                	sw	a5,24(a0)
  sched();
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	d1c080e7          	jalr	-740(ra) # 800020d6 <sched>
  p->chan = 0;
    800023c2:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800023c6:	bff9                	j	800023a4 <sleep+0x5a>

00000000800023c8 <wait>:
{
    800023c8:	715d                	addi	sp,sp,-80
    800023ca:	e486                	sd	ra,72(sp)
    800023cc:	e0a2                	sd	s0,64(sp)
    800023ce:	fc26                	sd	s1,56(sp)
    800023d0:	f84a                	sd	s2,48(sp)
    800023d2:	f44e                	sd	s3,40(sp)
    800023d4:	f052                	sd	s4,32(sp)
    800023d6:	ec56                	sd	s5,24(sp)
    800023d8:	e85a                	sd	s6,16(sp)
    800023da:	e45e                	sd	s7,8(sp)
    800023dc:	e062                	sd	s8,0(sp)
    800023de:	0880                	addi	s0,sp,80
    800023e0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	6a4080e7          	jalr	1700(ra) # 80001a86 <myproc>
    800023ea:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023ec:	8c2a                	mv	s8,a0
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	7e8080e7          	jalr	2024(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023f6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023f8:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023fa:	00021997          	auipc	s3,0x21
    800023fe:	cbe98993          	addi	s3,s3,-834 # 800230b8 <tickslock>
        havekids = 1;
    80002402:	4a85                	li	s5,1
    havekids = 0;
    80002404:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002406:	0000f497          	auipc	s1,0xf
    8000240a:	2b248493          	addi	s1,s1,690 # 800116b8 <proc>
    8000240e:	a08d                	j	80002470 <wait+0xa8>
          pid = np->pid;
    80002410:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002414:	000b0e63          	beqz	s6,80002430 <wait+0x68>
    80002418:	4691                	li	a3,4
    8000241a:	03448613          	addi	a2,s1,52
    8000241e:	85da                	mv	a1,s6
    80002420:	05093503          	ld	a0,80(s2)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	218080e7          	jalr	536(ra) # 8000163c <copyout>
    8000242c:	02054263          	bltz	a0,80002450 <wait+0x88>
          freeproc(np);
    80002430:	8526                	mv	a0,s1
    80002432:	00000097          	auipc	ra,0x0
    80002436:	806080e7          	jalr	-2042(ra) # 80001c38 <freeproc>
          release(&np->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
          release(&p->lock);
    80002444:	854a                	mv	a0,s2
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	844080e7          	jalr	-1980(ra) # 80000c8a <release>
          return pid;
    8000244e:	a8a9                	j	800024a8 <wait+0xe0>
            release(&np->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	838080e7          	jalr	-1992(ra) # 80000c8a <release>
            release(&p->lock);
    8000245a:	854a                	mv	a0,s2
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	82e080e7          	jalr	-2002(ra) # 80000c8a <release>
            return -1;
    80002464:	59fd                	li	s3,-1
    80002466:	a089                	j	800024a8 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002468:	46848493          	addi	s1,s1,1128
    8000246c:	03348463          	beq	s1,s3,80002494 <wait+0xcc>
      if(np->parent == p){
    80002470:	709c                	ld	a5,32(s1)
    80002472:	ff279be3          	bne	a5,s2,80002468 <wait+0xa0>
        acquire(&np->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	75e080e7          	jalr	1886(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	f94787e3          	beq	a5,s4,80002410 <wait+0x48>
        release(&np->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
        havekids = 1;
    80002490:	8756                	mv	a4,s5
    80002492:	bfd9                	j	80002468 <wait+0xa0>
    if(!havekids || p->killed){
    80002494:	c701                	beqz	a4,8000249c <wait+0xd4>
    80002496:	03092783          	lw	a5,48(s2)
    8000249a:	c785                	beqz	a5,800024c2 <wait+0xfa>
      release(&p->lock);
    8000249c:	854a                	mv	a0,s2
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
      return -1;
    800024a6:	59fd                	li	s3,-1
}
    800024a8:	854e                	mv	a0,s3
    800024aa:	60a6                	ld	ra,72(sp)
    800024ac:	6406                	ld	s0,64(sp)
    800024ae:	74e2                	ld	s1,56(sp)
    800024b0:	7942                	ld	s2,48(sp)
    800024b2:	79a2                	ld	s3,40(sp)
    800024b4:	7a02                	ld	s4,32(sp)
    800024b6:	6ae2                	ld	s5,24(sp)
    800024b8:	6b42                	ld	s6,16(sp)
    800024ba:	6ba2                	ld	s7,8(sp)
    800024bc:	6c02                	ld	s8,0(sp)
    800024be:	6161                	addi	sp,sp,80
    800024c0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800024c2:	85e2                	mv	a1,s8
    800024c4:	854a                	mv	a0,s2
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	e84080e7          	jalr	-380(ra) # 8000234a <sleep>
    havekids = 0;
    800024ce:	bf1d                	j	80002404 <wait+0x3c>

00000000800024d0 <wakeup>:
{
    800024d0:	7139                	addi	sp,sp,-64
    800024d2:	fc06                	sd	ra,56(sp)
    800024d4:	f822                	sd	s0,48(sp)
    800024d6:	f426                	sd	s1,40(sp)
    800024d8:	f04a                	sd	s2,32(sp)
    800024da:	ec4e                	sd	s3,24(sp)
    800024dc:	e852                	sd	s4,16(sp)
    800024de:	e456                	sd	s5,8(sp)
    800024e0:	0080                	addi	s0,sp,64
    800024e2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	1d448493          	addi	s1,s1,468 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024ec:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024ee:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024f0:	00021917          	auipc	s2,0x21
    800024f4:	bc890913          	addi	s2,s2,-1080 # 800230b8 <tickslock>
    800024f8:	a821                	j	80002510 <wakeup+0x40>
      p->state = RUNNABLE;
    800024fa:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	78a080e7          	jalr	1930(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002508:	46848493          	addi	s1,s1,1128
    8000250c:	01248e63          	beq	s1,s2,80002528 <wakeup+0x58>
    acquire(&p->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	6c4080e7          	jalr	1732(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000251a:	4c9c                	lw	a5,24(s1)
    8000251c:	ff3791e3          	bne	a5,s3,800024fe <wakeup+0x2e>
    80002520:	749c                	ld	a5,40(s1)
    80002522:	fd479ee3          	bne	a5,s4,800024fe <wakeup+0x2e>
    80002526:	bfd1                	j	800024fa <wakeup+0x2a>
}
    80002528:	70e2                	ld	ra,56(sp)
    8000252a:	7442                	ld	s0,48(sp)
    8000252c:	74a2                	ld	s1,40(sp)
    8000252e:	7902                	ld	s2,32(sp)
    80002530:	69e2                	ld	s3,24(sp)
    80002532:	6a42                	ld	s4,16(sp)
    80002534:	6aa2                	ld	s5,8(sp)
    80002536:	6121                	addi	sp,sp,64
    80002538:	8082                	ret

000000008000253a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000253a:	7179                	addi	sp,sp,-48
    8000253c:	f406                	sd	ra,40(sp)
    8000253e:	f022                	sd	s0,32(sp)
    80002540:	ec26                	sd	s1,24(sp)
    80002542:	e84a                	sd	s2,16(sp)
    80002544:	e44e                	sd	s3,8(sp)
    80002546:	1800                	addi	s0,sp,48
    80002548:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000254a:	0000f497          	auipc	s1,0xf
    8000254e:	16e48493          	addi	s1,s1,366 # 800116b8 <proc>
    80002552:	00021997          	auipc	s3,0x21
    80002556:	b6698993          	addi	s3,s3,-1178 # 800230b8 <tickslock>
    acquire(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	67a080e7          	jalr	1658(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002564:	5c9c                	lw	a5,56(s1)
    80002566:	01278d63          	beq	a5,s2,80002580 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	71e080e7          	jalr	1822(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002574:	46848493          	addi	s1,s1,1128
    80002578:	ff3491e3          	bne	s1,s3,8000255a <kill+0x20>
  }
  return -1;
    8000257c:	557d                	li	a0,-1
    8000257e:	a829                	j	80002598 <kill+0x5e>
      p->killed = 1;
    80002580:	4785                	li	a5,1
    80002582:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002584:	4c98                	lw	a4,24(s1)
    80002586:	4785                	li	a5,1
    80002588:	00f70f63          	beq	a4,a5,800025a6 <kill+0x6c>
      release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6fc080e7          	jalr	1788(ra) # 80000c8a <release>
      return 0;
    80002596:	4501                	li	a0,0
}
    80002598:	70a2                	ld	ra,40(sp)
    8000259a:	7402                	ld	s0,32(sp)
    8000259c:	64e2                	ld	s1,24(sp)
    8000259e:	6942                	ld	s2,16(sp)
    800025a0:	69a2                	ld	s3,8(sp)
    800025a2:	6145                	addi	sp,sp,48
    800025a4:	8082                	ret
        p->state = RUNNABLE;
    800025a6:	4789                	li	a5,2
    800025a8:	cc9c                	sw	a5,24(s1)
    800025aa:	b7cd                	j	8000258c <kill+0x52>

00000000800025ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	84aa                	mv	s1,a0
    800025be:	892e                	mv	s2,a1
    800025c0:	89b2                	mv	s3,a2
    800025c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	4c2080e7          	jalr	1218(ra) # 80001a86 <myproc>
  if(user_dst){
    800025cc:	c08d                	beqz	s1,800025ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025ce:	86d2                	mv	a3,s4
    800025d0:	864e                	mv	a2,s3
    800025d2:	85ca                	mv	a1,s2
    800025d4:	6928                	ld	a0,80(a0)
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	066080e7          	jalr	102(ra) # 8000163c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6a02                	ld	s4,0(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
    memmove((char *)dst, src, len);
    800025ee:	000a061b          	sext.w	a2,s4
    800025f2:	85ce                	mv	a1,s3
    800025f4:	854a                	mv	a0,s2
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	73c080e7          	jalr	1852(ra) # 80000d32 <memmove>
    return 0;
    800025fe:	8526                	mv	a0,s1
    80002600:	bff9                	j	800025de <either_copyout+0x32>

0000000080002602 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002602:	7179                	addi	sp,sp,-48
    80002604:	f406                	sd	ra,40(sp)
    80002606:	f022                	sd	s0,32(sp)
    80002608:	ec26                	sd	s1,24(sp)
    8000260a:	e84a                	sd	s2,16(sp)
    8000260c:	e44e                	sd	s3,8(sp)
    8000260e:	e052                	sd	s4,0(sp)
    80002610:	1800                	addi	s0,sp,48
    80002612:	892a                	mv	s2,a0
    80002614:	84ae                	mv	s1,a1
    80002616:	89b2                	mv	s3,a2
    80002618:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	46c080e7          	jalr	1132(ra) # 80001a86 <myproc>
  if(user_src){
    80002622:	c08d                	beqz	s1,80002644 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002624:	86d2                	mv	a3,s4
    80002626:	864e                	mv	a2,s3
    80002628:	85ca                	mv	a1,s2
    8000262a:	6928                	ld	a0,80(a0)
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	09c080e7          	jalr	156(ra) # 800016c8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002634:	70a2                	ld	ra,40(sp)
    80002636:	7402                	ld	s0,32(sp)
    80002638:	64e2                	ld	s1,24(sp)
    8000263a:	6942                	ld	s2,16(sp)
    8000263c:	69a2                	ld	s3,8(sp)
    8000263e:	6a02                	ld	s4,0(sp)
    80002640:	6145                	addi	sp,sp,48
    80002642:	8082                	ret
    memmove(dst, (char*)src, len);
    80002644:	000a061b          	sext.w	a2,s4
    80002648:	85ce                	mv	a1,s3
    8000264a:	854a                	mv	a0,s2
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	6e6080e7          	jalr	1766(ra) # 80000d32 <memmove>
    return 0;
    80002654:	8526                	mv	a0,s1
    80002656:	bff9                	j	80002634 <either_copyin+0x32>

0000000080002658 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002658:	715d                	addi	sp,sp,-80
    8000265a:	e486                	sd	ra,72(sp)
    8000265c:	e0a2                	sd	s0,64(sp)
    8000265e:	fc26                	sd	s1,56(sp)
    80002660:	f84a                	sd	s2,48(sp)
    80002662:	f44e                	sd	s3,40(sp)
    80002664:	f052                	sd	s4,32(sp)
    80002666:	ec56                	sd	s5,24(sp)
    80002668:	e85a                	sd	s6,16(sp)
    8000266a:	e45e                	sd	s7,8(sp)
    8000266c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000266e:	00006517          	auipc	a0,0x6
    80002672:	a5a50513          	addi	a0,a0,-1446 # 800080c8 <digits+0x88>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f04080e7          	jalr	-252(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267e:	0000f497          	auipc	s1,0xf
    80002682:	19248493          	addi	s1,s1,402 # 80011810 <proc+0x158>
    80002686:	00021917          	auipc	s2,0x21
    8000268a:	b8a90913          	addi	s2,s2,-1142 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002690:	00006997          	auipc	s3,0x6
    80002694:	c2098993          	addi	s3,s3,-992 # 800082b0 <indent.1667+0xc0>
    printf("%d %s %s", p->pid, state, p->name);
    80002698:	00006a97          	auipc	s5,0x6
    8000269c:	c20a8a93          	addi	s5,s5,-992 # 800082b8 <indent.1667+0xc8>
    printf("\n");
    800026a0:	00006a17          	auipc	s4,0x6
    800026a4:	a28a0a13          	addi	s4,s4,-1496 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a8:	00006b97          	auipc	s7,0x6
    800026ac:	c48b8b93          	addi	s7,s7,-952 # 800082f0 <states.1731>
    800026b0:	a00d                	j	800026d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026b2:	ee06a583          	lw	a1,-288(a3)
    800026b6:	8556                	mv	a0,s5
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	ec2080e7          	jalr	-318(ra) # 8000057a <printf>
    printf("\n");
    800026c0:	8552                	mv	a0,s4
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	eb8080e7          	jalr	-328(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026ca:	46848493          	addi	s1,s1,1128
    800026ce:	03248163          	beq	s1,s2,800026f0 <procdump+0x98>
    if(p->state == UNUSED)
    800026d2:	86a6                	mv	a3,s1
    800026d4:	ec04a783          	lw	a5,-320(s1)
    800026d8:	dbed                	beqz	a5,800026ca <procdump+0x72>
      state = "???";
    800026da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	fcfb6be3          	bltu	s6,a5,800026b2 <procdump+0x5a>
    800026e0:	1782                	slli	a5,a5,0x20
    800026e2:	9381                	srli	a5,a5,0x20
    800026e4:	078e                	slli	a5,a5,0x3
    800026e6:	97de                	add	a5,a5,s7
    800026e8:	6390                	ld	a2,0(a5)
    800026ea:	f661                	bnez	a2,800026b2 <procdump+0x5a>
      state = "???";
    800026ec:	864e                	mv	a2,s3
    800026ee:	b7d1                	j	800026b2 <procdump+0x5a>
  }
}
    800026f0:	60a6                	ld	ra,72(sp)
    800026f2:	6406                	ld	s0,64(sp)
    800026f4:	74e2                	ld	s1,56(sp)
    800026f6:	7942                	ld	s2,48(sp)
    800026f8:	79a2                	ld	s3,40(sp)
    800026fa:	7a02                	ld	s4,32(sp)
    800026fc:	6ae2                	ld	s5,24(sp)
    800026fe:	6b42                	ld	s6,16(sp)
    80002700:	6ba2                	ld	s7,8(sp)
    80002702:	6161                	addi	sp,sp,80
    80002704:	8082                	ret

0000000080002706 <swtch>:
    80002706:	00153023          	sd	ra,0(a0)
    8000270a:	00253423          	sd	sp,8(a0)
    8000270e:	e900                	sd	s0,16(a0)
    80002710:	ed04                	sd	s1,24(a0)
    80002712:	03253023          	sd	s2,32(a0)
    80002716:	03353423          	sd	s3,40(a0)
    8000271a:	03453823          	sd	s4,48(a0)
    8000271e:	03553c23          	sd	s5,56(a0)
    80002722:	05653023          	sd	s6,64(a0)
    80002726:	05753423          	sd	s7,72(a0)
    8000272a:	05853823          	sd	s8,80(a0)
    8000272e:	05953c23          	sd	s9,88(a0)
    80002732:	07a53023          	sd	s10,96(a0)
    80002736:	07b53423          	sd	s11,104(a0)
    8000273a:	0005b083          	ld	ra,0(a1)
    8000273e:	0085b103          	ld	sp,8(a1)
    80002742:	6980                	ld	s0,16(a1)
    80002744:	6d84                	ld	s1,24(a1)
    80002746:	0205b903          	ld	s2,32(a1)
    8000274a:	0285b983          	ld	s3,40(a1)
    8000274e:	0305ba03          	ld	s4,48(a1)
    80002752:	0385ba83          	ld	s5,56(a1)
    80002756:	0405bb03          	ld	s6,64(a1)
    8000275a:	0485bb83          	ld	s7,72(a1)
    8000275e:	0505bc03          	ld	s8,80(a1)
    80002762:	0585bc83          	ld	s9,88(a1)
    80002766:	0605bd03          	ld	s10,96(a1)
    8000276a:	0685bd83          	ld	s11,104(a1)
    8000276e:	8082                	ret

0000000080002770 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002770:	1141                	addi	sp,sp,-16
    80002772:	e406                	sd	ra,8(sp)
    80002774:	e022                	sd	s0,0(sp)
    80002776:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002778:	00006597          	auipc	a1,0x6
    8000277c:	ba058593          	addi	a1,a1,-1120 # 80008318 <states.1731+0x28>
    80002780:	00021517          	auipc	a0,0x21
    80002784:	93850513          	addi	a0,a0,-1736 # 800230b8 <tickslock>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	3be080e7          	jalr	958(ra) # 80000b46 <initlock>
}
    80002790:	60a2                	ld	ra,8(sp)
    80002792:	6402                	ld	s0,0(sp)
    80002794:	0141                	addi	sp,sp,16
    80002796:	8082                	ret

0000000080002798 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002798:	1141                	addi	sp,sp,-16
    8000279a:	e422                	sd	s0,8(sp)
    8000279c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000279e:	00004797          	auipc	a5,0x4
    800027a2:	a0278793          	addi	a5,a5,-1534 # 800061a0 <kernelvec>
    800027a6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027aa:	6422                	ld	s0,8(sp)
    800027ac:	0141                	addi	sp,sp,16
    800027ae:	8082                	ret

00000000800027b0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027b0:	1141                	addi	sp,sp,-16
    800027b2:	e406                	sd	ra,8(sp)
    800027b4:	e022                	sd	s0,0(sp)
    800027b6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	2ce080e7          	jalr	718(ra) # 80001a86 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027c4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027ca:	00005617          	auipc	a2,0x5
    800027ce:	83660613          	addi	a2,a2,-1994 # 80007000 <_trampoline>
    800027d2:	00005697          	auipc	a3,0x5
    800027d6:	82e68693          	addi	a3,a3,-2002 # 80007000 <_trampoline>
    800027da:	8e91                	sub	a3,a3,a2
    800027dc:	040007b7          	lui	a5,0x4000
    800027e0:	17fd                	addi	a5,a5,-1
    800027e2:	07b2                	slli	a5,a5,0xc
    800027e4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027ea:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ec:	180026f3          	csrr	a3,satp
    800027f0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027f2:	6d38                	ld	a4,88(a0)
    800027f4:	6134                	ld	a3,64(a0)
    800027f6:	6585                	lui	a1,0x1
    800027f8:	96ae                	add	a3,a3,a1
    800027fa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027fc:	6d38                	ld	a4,88(a0)
    800027fe:	00000697          	auipc	a3,0x0
    80002802:	32c68693          	addi	a3,a3,812 # 80002b2a <usertrap>
    80002806:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002808:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000280a:	8692                	mv	a3,tp
    8000280c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002812:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002816:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000281e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002820:	6f18                	ld	a4,24(a4)
    80002822:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002826:	692c                	ld	a1,80(a0)
    80002828:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000282a:	00005717          	auipc	a4,0x5
    8000282e:	86670713          	addi	a4,a4,-1946 # 80007090 <userret>
    80002832:	8f11                	sub	a4,a4,a2
    80002834:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002836:	577d                	li	a4,-1
    80002838:	177e                	slli	a4,a4,0x3f
    8000283a:	8dd9                	or	a1,a1,a4
    8000283c:	02000537          	lui	a0,0x2000
    80002840:	157d                	addi	a0,a0,-1
    80002842:	0536                	slli	a0,a0,0xd
    80002844:	9782                	jalr	a5
}
    80002846:	60a2                	ld	ra,8(sp)
    80002848:	6402                	ld	s0,0(sp)
    8000284a:	0141                	addi	sp,sp,16
    8000284c:	8082                	ret

000000008000284e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000284e:	1101                	addi	sp,sp,-32
    80002850:	ec06                	sd	ra,24(sp)
    80002852:	e822                	sd	s0,16(sp)
    80002854:	e426                	sd	s1,8(sp)
    80002856:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002858:	00021497          	auipc	s1,0x21
    8000285c:	86048493          	addi	s1,s1,-1952 # 800230b8 <tickslock>
    80002860:	8526                	mv	a0,s1
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	374080e7          	jalr	884(ra) # 80000bd6 <acquire>
  ticks++;
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	7c650513          	addi	a0,a0,1990 # 80009030 <ticks>
    80002872:	411c                	lw	a5,0(a0)
    80002874:	2785                	addiw	a5,a5,1
    80002876:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	c58080e7          	jalr	-936(ra) # 800024d0 <wakeup>
  release(&tickslock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	408080e7          	jalr	1032(ra) # 80000c8a <release>
}
    8000288a:	60e2                	ld	ra,24(sp)
    8000288c:	6442                	ld	s0,16(sp)
    8000288e:	64a2                	ld	s1,8(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret

0000000080002894 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002894:	1101                	addi	sp,sp,-32
    80002896:	ec06                	sd	ra,24(sp)
    80002898:	e822                	sd	s0,16(sp)
    8000289a:	e426                	sd	s1,8(sp)
    8000289c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028a2:	00074d63          	bltz	a4,800028bc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028a6:	57fd                	li	a5,-1
    800028a8:	17fe                	slli	a5,a5,0x3f
    800028aa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028ac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028ae:	06f70363          	beq	a4,a5,80002914 <devintr+0x80>
  }
}
    800028b2:	60e2                	ld	ra,24(sp)
    800028b4:	6442                	ld	s0,16(sp)
    800028b6:	64a2                	ld	s1,8(sp)
    800028b8:	6105                	addi	sp,sp,32
    800028ba:	8082                	ret
     (scause & 0xff) == 9){
    800028bc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028c0:	46a5                	li	a3,9
    800028c2:	fed792e3          	bne	a5,a3,800028a6 <devintr+0x12>
    int irq = plic_claim();
    800028c6:	00004097          	auipc	ra,0x4
    800028ca:	9e2080e7          	jalr	-1566(ra) # 800062a8 <plic_claim>
    800028ce:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028d0:	47a9                	li	a5,10
    800028d2:	02f50763          	beq	a0,a5,80002900 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028d6:	4785                	li	a5,1
    800028d8:	02f50963          	beq	a0,a5,8000290a <devintr+0x76>
    return 1;
    800028dc:	4505                	li	a0,1
    } else if(irq){
    800028de:	d8f1                	beqz	s1,800028b2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028e0:	85a6                	mv	a1,s1
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a3e50513          	addi	a0,a0,-1474 # 80008320 <states.1731+0x30>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c90080e7          	jalr	-880(ra) # 8000057a <printf>
      plic_complete(irq);
    800028f2:	8526                	mv	a0,s1
    800028f4:	00004097          	auipc	ra,0x4
    800028f8:	9d8080e7          	jalr	-1576(ra) # 800062cc <plic_complete>
    return 1;
    800028fc:	4505                	li	a0,1
    800028fe:	bf55                	j	800028b2 <devintr+0x1e>
      uartintr();
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	09a080e7          	jalr	154(ra) # 8000099a <uartintr>
    80002908:	b7ed                	j	800028f2 <devintr+0x5e>
      virtio_disk_intr();
    8000290a:	00004097          	auipc	ra,0x4
    8000290e:	ea2080e7          	jalr	-350(ra) # 800067ac <virtio_disk_intr>
    80002912:	b7c5                	j	800028f2 <devintr+0x5e>
    if(cpuid() == 0){
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	146080e7          	jalr	326(ra) # 80001a5a <cpuid>
    8000291c:	c901                	beqz	a0,8000292c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000291e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002922:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002924:	14479073          	csrw	sip,a5
    return 2;
    80002928:	4509                	li	a0,2
    8000292a:	b761                	j	800028b2 <devintr+0x1e>
      clockintr();
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	f22080e7          	jalr	-222(ra) # 8000284e <clockintr>
    80002934:	b7ed                	j	8000291e <devintr+0x8a>

0000000080002936 <kerneltrap>:
{
    80002936:	7179                	addi	sp,sp,-48
    80002938:	f406                	sd	ra,40(sp)
    8000293a:	f022                	sd	s0,32(sp)
    8000293c:	ec26                	sd	s1,24(sp)
    8000293e:	e84a                	sd	s2,16(sp)
    80002940:	e44e                	sd	s3,8(sp)
    80002942:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002944:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002948:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002950:	1004f793          	andi	a5,s1,256
    80002954:	cb85                	beqz	a5,80002984 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002956:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000295a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000295c:	ef85                	bnez	a5,80002994 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	f36080e7          	jalr	-202(ra) # 80002894 <devintr>
    80002966:	cd1d                	beqz	a0,800029a4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002968:	4789                	li	a5,2
    8000296a:	06f50a63          	beq	a0,a5,800029de <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000296e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002972:	10049073          	csrw	sstatus,s1
}
    80002976:	70a2                	ld	ra,40(sp)
    80002978:	7402                	ld	s0,32(sp)
    8000297a:	64e2                	ld	s1,24(sp)
    8000297c:	6942                	ld	s2,16(sp)
    8000297e:	69a2                	ld	s3,8(sp)
    80002980:	6145                	addi	sp,sp,48
    80002982:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9bc50513          	addi	a0,a0,-1604 # 80008340 <states.1731+0x50>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	ba4080e7          	jalr	-1116(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	9d450513          	addi	a0,a0,-1580 # 80008368 <states.1731+0x78>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	b94080e7          	jalr	-1132(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    800029a4:	85ce                	mv	a1,s3
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	9e250513          	addi	a0,a0,-1566 # 80008388 <states.1731+0x98>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	bcc080e7          	jalr	-1076(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	9da50513          	addi	a0,a0,-1574 # 80008398 <states.1731+0xa8>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	bb4080e7          	jalr	-1100(ra) # 8000057a <printf>
    panic("kerneltrap");
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9e250513          	addi	a0,a0,-1566 # 800083b0 <states.1731+0xc0>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	b5a080e7          	jalr	-1190(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029de:	fffff097          	auipc	ra,0xfffff
    800029e2:	0a8080e7          	jalr	168(ra) # 80001a86 <myproc>
    800029e6:	d541                	beqz	a0,8000296e <kerneltrap+0x38>
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	09e080e7          	jalr	158(ra) # 80001a86 <myproc>
    800029f0:	4d18                	lw	a4,24(a0)
    800029f2:	478d                	li	a5,3
    800029f4:	f6f71de3          	bne	a4,a5,8000296e <kerneltrap+0x38>
    yield();
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	916080e7          	jalr	-1770(ra) # 8000230e <yield>
    80002a00:	b7bd                	j	8000296e <kerneltrap+0x38>

0000000080002a02 <mmapalloc>:

int mmapalloc(uint64 va){
    80002a02:	7139                	addi	sp,sp,-64
    80002a04:	fc06                	sd	ra,56(sp)
    80002a06:	f822                	sd	s0,48(sp)
    80002a08:	f426                	sd	s1,40(sp)
    80002a0a:	f04a                	sd	s2,32(sp)
    80002a0c:	ec4e                	sd	s3,24(sp)
    80002a0e:	e852                	sd	s4,16(sp)
    80002a10:	e456                	sd	s5,8(sp)
    80002a12:	e05a                	sd	s6,0(sp)
    80002a14:	0080                	addi	s0,sp,64
    80002a16:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	06e080e7          	jalr	110(ra) # 80001a86 <myproc>
    80002a20:	8a2a                	mv	s4,a0
    char *mem;

    if((mem = kalloc()) == 0){
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	0c4080e7          	jalr	196(ra) # 80000ae6 <kalloc>
    80002a2a:	cd75                	beqz	a0,80002b26 <mmapalloc+0x124>
    80002a2c:	89aa                	mv	s3,a0
      return -1;
    }
    
    memset(mem,0,PGSIZE);
    80002a2e:	6605                	lui	a2,0x1
    80002a30:	4581                	li	a1,0
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	2a0080e7          	jalr	672(ra) # 80000cd2 <memset>
    for(int i = 0;i < VMASIZE; ++i){
    80002a3a:	168a0793          	addi	a5,s4,360
    80002a3e:	4481                	li	s1,0
      struct VMA *vma = &p->vma[i];
      if(va >= vma->address && va < vma->address + vma->length && vma->valid == 1){
    80002a40:	4505                	li	a0,1
    for(int i = 0;i < VMASIZE; ++i){
    80002a42:	4641                	li	a2,16
    80002a44:	a829                	j	80002a5e <mmapalloc+0x5c>
        struct inode *ip = vma->f->ip;
        
        ilock(ip);
        int cnt = 0;
        if((cnt = readi(ip,0,(uint64)mem,vma->offset + va - vma->address,PGSIZE)) < 0){
          iunlock(ip);
    80002a46:	855a                	mv	a0,s6
    80002a48:	00001097          	auipc	ra,0x1
    80002a4c:	f7a080e7          	jalr	-134(ra) # 800039c2 <iunlock>
          return -1;
    80002a50:	557d                	li	a0,-1
    80002a52:	a0c1                	j	80002b12 <mmapalloc+0x110>
    for(int i = 0;i < VMASIZE; ++i){
    80002a54:	2485                	addiw	s1,s1,1
    80002a56:	03078793          	addi	a5,a5,48 # 4000030 <_entry-0x7bffffd0>
    80002a5a:	0ac48663          	beq	s1,a2,80002b06 <mmapalloc+0x104>
      if(va >= vma->address && va < vma->address + vma->length && vma->valid == 1){
    80002a5e:	6398                	ld	a4,0(a5)
    80002a60:	fee96ae3          	bltu	s2,a4,80002a54 <mmapalloc+0x52>
    80002a64:	678c                	ld	a1,8(a5)
    80002a66:	972e                	add	a4,a4,a1
    80002a68:	fee976e3          	bgeu	s2,a4,80002a54 <mmapalloc+0x52>
    80002a6c:	5798                	lw	a4,40(a5)
    80002a6e:	fea713e3          	bne	a4,a0,80002a54 <mmapalloc+0x52>
        va = PGROUNDDOWN(va);
    80002a72:	7afd                	lui	s5,0xfffff
    80002a74:	01597ab3          	and	s5,s2,s5
        struct inode *ip = vma->f->ip;
    80002a78:	00149913          	slli	s2,s1,0x1
    80002a7c:	9926                	add	s2,s2,s1
    80002a7e:	0912                	slli	s2,s2,0x4
    80002a80:	9952                	add	s2,s2,s4
    80002a82:	18893783          	ld	a5,392(s2)
    80002a86:	0187bb03          	ld	s6,24(a5)
        ilock(ip);
    80002a8a:	855a                	mv	a0,s6
    80002a8c:	00001097          	auipc	ra,0x1
    80002a90:	e5e080e7          	jalr	-418(ra) # 800038ea <ilock>
        if((cnt = readi(ip,0,(uint64)mem,vma->offset + va - vma->address,PGSIZE)) < 0){
    80002a94:	18092783          	lw	a5,384(s2)
    80002a98:	015787bb          	addw	a5,a5,s5
    80002a9c:	16893683          	ld	a3,360(s2)
    80002aa0:	6705                	lui	a4,0x1
    80002aa2:	40d786bb          	subw	a3,a5,a3
    80002aa6:	864e                	mv	a2,s3
    80002aa8:	4581                	li	a1,0
    80002aaa:	855a                	mv	a0,s6
    80002aac:	00001097          	auipc	ra,0x1
    80002ab0:	108080e7          	jalr	264(ra) # 80003bb4 <readi>
    80002ab4:	f80549e3          	bltz	a0,80002a46 <mmapalloc+0x44>
        }
        iunlock(ip);
    80002ab8:	855a                	mv	a0,s6
    80002aba:	00001097          	auipc	ra,0x1
    80002abe:	f08080e7          	jalr	-248(ra) # 800039c2 <iunlock>

        int prot = 0;
        if(vma->prot & PROT_READ){
    80002ac2:	00149793          	slli	a5,s1,0x1
    80002ac6:	97a6                	add	a5,a5,s1
    80002ac8:	0792                	slli	a5,a5,0x4
    80002aca:	97d2                	add	a5,a5,s4
    80002acc:	1787a783          	lw	a5,376(a5)
    80002ad0:	0017f713          	andi	a4,a5,1
    80002ad4:	c311                	beqz	a4,80002ad8 <mmapalloc+0xd6>
          prot |= PTE_R;
    80002ad6:	4709                	li	a4,2
        }
        if(vma->prot & PROT_WRITE){
    80002ad8:	8b89                	andi	a5,a5,2
    80002ada:	c399                	beqz	a5,80002ae0 <mmapalloc+0xde>
          prot |= PTE_W;
    80002adc:	00476713          	ori	a4,a4,4
        }
        prot |= PTE_U;
        if(mappages(p->pagetable,va,PGSIZE,(uint64)mem,prot) != 0){
    80002ae0:	01076713          	ori	a4,a4,16
    80002ae4:	86ce                	mv	a3,s3
    80002ae6:	6605                	lui	a2,0x1
    80002ae8:	85d6                	mv	a1,s5
    80002aea:	050a3503          	ld	a0,80(s4)
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	5b8080e7          	jalr	1464(ra) # 800010a6 <mappages>
    80002af6:	cd11                	beqz	a0,80002b12 <mmapalloc+0x110>
          kfree(mem);
    80002af8:	854e                	mv	a0,s3
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	ef0080e7          	jalr	-272(ra) # 800009ea <kfree>
          return -1;
    80002b02:	557d                	li	a0,-1
    80002b04:	a039                	j	80002b12 <mmapalloc+0x110>
        }
        return 0;
      }
    }
    kfree(mem);
    80002b06:	854e                	mv	a0,s3
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	ee2080e7          	jalr	-286(ra) # 800009ea <kfree>
    return -1;
    80002b10:	557d                	li	a0,-1
    80002b12:	70e2                	ld	ra,56(sp)
    80002b14:	7442                	ld	s0,48(sp)
    80002b16:	74a2                	ld	s1,40(sp)
    80002b18:	7902                	ld	s2,32(sp)
    80002b1a:	69e2                	ld	s3,24(sp)
    80002b1c:	6a42                	ld	s4,16(sp)
    80002b1e:	6aa2                	ld	s5,8(sp)
    80002b20:	6b02                	ld	s6,0(sp)
    80002b22:	6121                	addi	sp,sp,64
    80002b24:	8082                	ret
      return -1;
    80002b26:	557d                	li	a0,-1
    80002b28:	b7ed                	j	80002b12 <mmapalloc+0x110>

0000000080002b2a <usertrap>:
{
    80002b2a:	1101                	addi	sp,sp,-32
    80002b2c:	ec06                	sd	ra,24(sp)
    80002b2e:	e822                	sd	s0,16(sp)
    80002b30:	e426                	sd	s1,8(sp)
    80002b32:	e04a                	sd	s2,0(sp)
    80002b34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b3a:	1007f793          	andi	a5,a5,256
    80002b3e:	ebb5                	bnez	a5,80002bb2 <usertrap+0x88>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b40:	00003797          	auipc	a5,0x3
    80002b44:	66078793          	addi	a5,a5,1632 # 800061a0 <kernelvec>
    80002b48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	f3a080e7          	jalr	-198(ra) # 80001a86 <myproc>
    80002b54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b56:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102773          	csrr	a4,sepc
    80002b5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b62:	47a1                	li	a5,8
    80002b64:	04f70f63          	beq	a4,a5,80002bc2 <usertrap+0x98>
    80002b68:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    80002b6c:	47b5                	li	a5,13
    80002b6e:	00f70763          	beq	a4,a5,80002b7c <usertrap+0x52>
    80002b72:	14202773          	csrr	a4,scause
    80002b76:	47bd                	li	a5,15
    80002b78:	0af71a63          	bne	a4,a5,80002c2c <usertrap+0x102>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b7c:	14302773          	csrr	a4,stval
    if(r_stval() > MAXVA || r_stval() > p->sz){
    80002b80:	4785                	li	a5,1
    80002b82:	179a                	slli	a5,a5,0x26
    80002b84:	00e7e763          	bltu	a5,a4,80002b92 <usertrap+0x68>
    80002b88:	143027f3          	csrr	a5,stval
    80002b8c:	64b8                	ld	a4,72(s1)
    80002b8e:	06f77c63          	bgeu	a4,a5,80002c06 <usertrap+0xdc>
      p->killed = 1;
    80002b92:	4785                	li	a5,1
    80002b94:	d89c                	sw	a5,48(s1)
{
    80002b96:	4901                	li	s2,0
    exit(-1);
    80002b98:	557d                	li	a0,-1
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	612080e7          	jalr	1554(ra) # 800021ac <exit>
  if(which_dev == 2)
    80002ba2:	4789                	li	a5,2
    80002ba4:	04f91163          	bne	s2,a5,80002be6 <usertrap+0xbc>
    yield();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	766080e7          	jalr	1894(ra) # 8000230e <yield>
    80002bb0:	a81d                	j	80002be6 <usertrap+0xbc>
    panic("usertrap: not from user mode");
    80002bb2:	00006517          	auipc	a0,0x6
    80002bb6:	80e50513          	addi	a0,a0,-2034 # 800083c0 <states.1731+0xd0>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	976080e7          	jalr	-1674(ra) # 80000530 <panic>
    if(p->killed)
    80002bc2:	591c                	lw	a5,48(a0)
    80002bc4:	eb9d                	bnez	a5,80002bfa <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002bc6:	6cb8                	ld	a4,88(s1)
    80002bc8:	6f1c                	ld	a5,24(a4)
    80002bca:	0791                	addi	a5,a5,4
    80002bcc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bd2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	212080e7          	jalr	530(ra) # 80002dec <syscall>
  if(p->killed)
    80002be2:	589c                	lw	a5,48(s1)
    80002be4:	e7d9                	bnez	a5,80002c72 <usertrap+0x148>
  usertrapret();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	bca080e7          	jalr	-1078(ra) # 800027b0 <usertrapret>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
      exit(-1);
    80002bfa:	557d                	li	a0,-1
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	5b0080e7          	jalr	1456(ra) # 800021ac <exit>
    80002c04:	b7c9                	j	80002bc6 <usertrap+0x9c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c06:	14302573          	csrr	a0,stval
    if(mmapalloc(r_stval()) < 0){
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	df8080e7          	jalr	-520(ra) # 80002a02 <mmapalloc>
    80002c12:	fc0558e3          	bgez	a0,80002be2 <usertrap+0xb8>
      printf("mmapalloc\n");
    80002c16:	00005517          	auipc	a0,0x5
    80002c1a:	7ca50513          	addi	a0,a0,1994 # 800083e0 <states.1731+0xf0>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	95c080e7          	jalr	-1700(ra) # 8000057a <printf>
      p->killed = 1;
    80002c26:	4785                	li	a5,1
    80002c28:	d89c                	sw	a5,48(s1)
      goto bad;
    80002c2a:	b7b5                	j	80002b96 <usertrap+0x6c>
  else if((which_dev = devintr()) != 0){
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	c68080e7          	jalr	-920(ra) # 80002894 <devintr>
    80002c34:	892a                	mv	s2,a0
    80002c36:	c501                	beqz	a0,80002c3e <usertrap+0x114>
  if(p->killed)
    80002c38:	589c                	lw	a5,48(s1)
    80002c3a:	d7a5                	beqz	a5,80002ba2 <usertrap+0x78>
    80002c3c:	bfb1                	j	80002b98 <usertrap+0x6e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c3e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c42:	5c90                	lw	a2,56(s1)
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7ac50513          	addi	a0,a0,1964 # 800083f0 <states.1731+0x100>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	92e080e7          	jalr	-1746(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c58:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7c450513          	addi	a0,a0,1988 # 80008420 <states.1731+0x130>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	916080e7          	jalr	-1770(ra) # 8000057a <printf>
    p->killed = 1;
    80002c6c:	4785                	li	a5,1
    80002c6e:	d89c                	sw	a5,48(s1)
    80002c70:	b71d                	j	80002b96 <usertrap+0x6c>
  if(p->killed)
    80002c72:	4901                	li	s2,0
    80002c74:	b715                	j	80002b98 <usertrap+0x6e>

0000000080002c76 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	1000                	addi	s0,sp,32
    80002c80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	e04080e7          	jalr	-508(ra) # 80001a86 <myproc>
  switch (n) {
    80002c8a:	4795                	li	a5,5
    80002c8c:	0497e163          	bltu	a5,s1,80002cce <argraw+0x58>
    80002c90:	048a                	slli	s1,s1,0x2
    80002c92:	00005717          	auipc	a4,0x5
    80002c96:	7d670713          	addi	a4,a4,2006 # 80008468 <states.1731+0x178>
    80002c9a:	94ba                	add	s1,s1,a4
    80002c9c:	409c                	lw	a5,0(s1)
    80002c9e:	97ba                	add	a5,a5,a4
    80002ca0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ca2:	6d3c                	ld	a5,88(a0)
    80002ca4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	64a2                	ld	s1,8(sp)
    80002cac:	6105                	addi	sp,sp,32
    80002cae:	8082                	ret
    return p->trapframe->a1;
    80002cb0:	6d3c                	ld	a5,88(a0)
    80002cb2:	7fa8                	ld	a0,120(a5)
    80002cb4:	bfcd                	j	80002ca6 <argraw+0x30>
    return p->trapframe->a2;
    80002cb6:	6d3c                	ld	a5,88(a0)
    80002cb8:	63c8                	ld	a0,128(a5)
    80002cba:	b7f5                	j	80002ca6 <argraw+0x30>
    return p->trapframe->a3;
    80002cbc:	6d3c                	ld	a5,88(a0)
    80002cbe:	67c8                	ld	a0,136(a5)
    80002cc0:	b7dd                	j	80002ca6 <argraw+0x30>
    return p->trapframe->a4;
    80002cc2:	6d3c                	ld	a5,88(a0)
    80002cc4:	6bc8                	ld	a0,144(a5)
    80002cc6:	b7c5                	j	80002ca6 <argraw+0x30>
    return p->trapframe->a5;
    80002cc8:	6d3c                	ld	a5,88(a0)
    80002cca:	6fc8                	ld	a0,152(a5)
    80002ccc:	bfe9                	j	80002ca6 <argraw+0x30>
  panic("argraw");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	77250513          	addi	a0,a0,1906 # 80008440 <states.1731+0x150>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	85a080e7          	jalr	-1958(ra) # 80000530 <panic>

0000000080002cde <fetchaddr>:
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	e426                	sd	s1,8(sp)
    80002ce6:	e04a                	sd	s2,0(sp)
    80002ce8:	1000                	addi	s0,sp,32
    80002cea:	84aa                	mv	s1,a0
    80002cec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	d98080e7          	jalr	-616(ra) # 80001a86 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cf6:	653c                	ld	a5,72(a0)
    80002cf8:	02f4f863          	bgeu	s1,a5,80002d28 <fetchaddr+0x4a>
    80002cfc:	00848713          	addi	a4,s1,8
    80002d00:	02e7e663          	bltu	a5,a4,80002d2c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d04:	46a1                	li	a3,8
    80002d06:	8626                	mv	a2,s1
    80002d08:	85ca                	mv	a1,s2
    80002d0a:	6928                	ld	a0,80(a0)
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	9bc080e7          	jalr	-1604(ra) # 800016c8 <copyin>
    80002d14:	00a03533          	snez	a0,a0
    80002d18:	40a00533          	neg	a0,a0
}
    80002d1c:	60e2                	ld	ra,24(sp)
    80002d1e:	6442                	ld	s0,16(sp)
    80002d20:	64a2                	ld	s1,8(sp)
    80002d22:	6902                	ld	s2,0(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret
    return -1;
    80002d28:	557d                	li	a0,-1
    80002d2a:	bfcd                	j	80002d1c <fetchaddr+0x3e>
    80002d2c:	557d                	li	a0,-1
    80002d2e:	b7fd                	j	80002d1c <fetchaddr+0x3e>

0000000080002d30 <fetchstr>:
{
    80002d30:	7179                	addi	sp,sp,-48
    80002d32:	f406                	sd	ra,40(sp)
    80002d34:	f022                	sd	s0,32(sp)
    80002d36:	ec26                	sd	s1,24(sp)
    80002d38:	e84a                	sd	s2,16(sp)
    80002d3a:	e44e                	sd	s3,8(sp)
    80002d3c:	1800                	addi	s0,sp,48
    80002d3e:	892a                	mv	s2,a0
    80002d40:	84ae                	mv	s1,a1
    80002d42:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	d42080e7          	jalr	-702(ra) # 80001a86 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d4c:	86ce                	mv	a3,s3
    80002d4e:	864a                	mv	a2,s2
    80002d50:	85a6                	mv	a1,s1
    80002d52:	6928                	ld	a0,80(a0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	a00080e7          	jalr	-1536(ra) # 80001754 <copyinstr>
  if(err < 0)
    80002d5c:	00054763          	bltz	a0,80002d6a <fetchstr+0x3a>
  return strlen(buf);
    80002d60:	8526                	mv	a0,s1
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	0f8080e7          	jalr	248(ra) # 80000e5a <strlen>
}
    80002d6a:	70a2                	ld	ra,40(sp)
    80002d6c:	7402                	ld	s0,32(sp)
    80002d6e:	64e2                	ld	s1,24(sp)
    80002d70:	6942                	ld	s2,16(sp)
    80002d72:	69a2                	ld	s3,8(sp)
    80002d74:	6145                	addi	sp,sp,48
    80002d76:	8082                	ret

0000000080002d78 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	e426                	sd	s1,8(sp)
    80002d80:	1000                	addi	s0,sp,32
    80002d82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	ef2080e7          	jalr	-270(ra) # 80002c76 <argraw>
    80002d8c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d8e:	4501                	li	a0,0
    80002d90:	60e2                	ld	ra,24(sp)
    80002d92:	6442                	ld	s0,16(sp)
    80002d94:	64a2                	ld	s1,8(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret

0000000080002d9a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d9a:	1101                	addi	sp,sp,-32
    80002d9c:	ec06                	sd	ra,24(sp)
    80002d9e:	e822                	sd	s0,16(sp)
    80002da0:	e426                	sd	s1,8(sp)
    80002da2:	1000                	addi	s0,sp,32
    80002da4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	ed0080e7          	jalr	-304(ra) # 80002c76 <argraw>
    80002dae:	e088                	sd	a0,0(s1)
  return 0;
}
    80002db0:	4501                	li	a0,0
    80002db2:	60e2                	ld	ra,24(sp)
    80002db4:	6442                	ld	s0,16(sp)
    80002db6:	64a2                	ld	s1,8(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	e426                	sd	s1,8(sp)
    80002dc4:	e04a                	sd	s2,0(sp)
    80002dc6:	1000                	addi	s0,sp,32
    80002dc8:	84ae                	mv	s1,a1
    80002dca:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	eaa080e7          	jalr	-342(ra) # 80002c76 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dd4:	864a                	mv	a2,s2
    80002dd6:	85a6                	mv	a1,s1
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	f58080e7          	jalr	-168(ra) # 80002d30 <fetchstr>
}
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	64a2                	ld	s1,8(sp)
    80002de6:	6902                	ld	s2,0(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret

0000000080002dec <syscall>:
[SYS_munmap]  sys_munmap
};

void
syscall(void)
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	e426                	sd	s1,8(sp)
    80002df4:	e04a                	sd	s2,0(sp)
    80002df6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	c8e080e7          	jalr	-882(ra) # 80001a86 <myproc>
    80002e00:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e02:	05853903          	ld	s2,88(a0)
    80002e06:	0a893783          	ld	a5,168(s2)
    80002e0a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e0e:	37fd                	addiw	a5,a5,-1
    80002e10:	4759                	li	a4,22
    80002e12:	00f76f63          	bltu	a4,a5,80002e30 <syscall+0x44>
    80002e16:	00369713          	slli	a4,a3,0x3
    80002e1a:	00005797          	auipc	a5,0x5
    80002e1e:	66678793          	addi	a5,a5,1638 # 80008480 <syscalls>
    80002e22:	97ba                	add	a5,a5,a4
    80002e24:	639c                	ld	a5,0(a5)
    80002e26:	c789                	beqz	a5,80002e30 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e28:	9782                	jalr	a5
    80002e2a:	06a93823          	sd	a0,112(s2)
    80002e2e:	a839                	j	80002e4c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e30:	15848613          	addi	a2,s1,344
    80002e34:	5c8c                	lw	a1,56(s1)
    80002e36:	00005517          	auipc	a0,0x5
    80002e3a:	61250513          	addi	a0,a0,1554 # 80008448 <states.1731+0x158>
    80002e3e:	ffffd097          	auipc	ra,0xffffd
    80002e42:	73c080e7          	jalr	1852(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e46:	6cbc                	ld	a5,88(s1)
    80002e48:	577d                	li	a4,-1
    80002e4a:	fbb8                	sd	a4,112(a5)
  }
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6902                	ld	s2,0(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e60:	fec40593          	addi	a1,s0,-20
    80002e64:	4501                	li	a0,0
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	f12080e7          	jalr	-238(ra) # 80002d78 <argint>
    return -1;
    80002e6e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e70:	00054963          	bltz	a0,80002e82 <sys_exit+0x2a>
  exit(n);
    80002e74:	fec42503          	lw	a0,-20(s0)
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	334080e7          	jalr	820(ra) # 800021ac <exit>
  return 0;  // not reached
    80002e80:	4781                	li	a5,0
}
    80002e82:	853e                	mv	a0,a5
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e8c:	1141                	addi	sp,sp,-16
    80002e8e:	e406                	sd	ra,8(sp)
    80002e90:	e022                	sd	s0,0(sp)
    80002e92:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	bf2080e7          	jalr	-1038(ra) # 80001a86 <myproc>
}
    80002e9c:	5d08                	lw	a0,56(a0)
    80002e9e:	60a2                	ld	ra,8(sp)
    80002ea0:	6402                	ld	s0,0(sp)
    80002ea2:	0141                	addi	sp,sp,16
    80002ea4:	8082                	ret

0000000080002ea6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ea6:	1141                	addi	sp,sp,-16
    80002ea8:	e406                	sd	ra,8(sp)
    80002eaa:	e022                	sd	s0,0(sp)
    80002eac:	0800                	addi	s0,sp,16
  return fork();
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	f98080e7          	jalr	-104(ra) # 80001e46 <fork>
}
    80002eb6:	60a2                	ld	ra,8(sp)
    80002eb8:	6402                	ld	s0,0(sp)
    80002eba:	0141                	addi	sp,sp,16
    80002ebc:	8082                	ret

0000000080002ebe <sys_wait>:

uint64
sys_wait(void)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ec6:	fe840593          	addi	a1,s0,-24
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	ece080e7          	jalr	-306(ra) # 80002d9a <argaddr>
    80002ed4:	87aa                	mv	a5,a0
    return -1;
    80002ed6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ed8:	0007c863          	bltz	a5,80002ee8 <sys_wait+0x2a>
  return wait(p);
    80002edc:	fe843503          	ld	a0,-24(s0)
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	4e8080e7          	jalr	1256(ra) # 800023c8 <wait>
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ef0:	7179                	addi	sp,sp,-48
    80002ef2:	f406                	sd	ra,40(sp)
    80002ef4:	f022                	sd	s0,32(sp)
    80002ef6:	ec26                	sd	s1,24(sp)
    80002ef8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002efa:	fdc40593          	addi	a1,s0,-36
    80002efe:	4501                	li	a0,0
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	e78080e7          	jalr	-392(ra) # 80002d78 <argint>
    80002f08:	87aa                	mv	a5,a0
    return -1;
    80002f0a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f0c:	0207c063          	bltz	a5,80002f2c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	b76080e7          	jalr	-1162(ra) # 80001a86 <myproc>
    80002f18:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f1a:	fdc42503          	lw	a0,-36(s0)
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	eb4080e7          	jalr	-332(ra) # 80001dd2 <growproc>
    80002f26:	00054863          	bltz	a0,80002f36 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f2a:	8526                	mv	a0,s1
}
    80002f2c:	70a2                	ld	ra,40(sp)
    80002f2e:	7402                	ld	s0,32(sp)
    80002f30:	64e2                	ld	s1,24(sp)
    80002f32:	6145                	addi	sp,sp,48
    80002f34:	8082                	ret
    return -1;
    80002f36:	557d                	li	a0,-1
    80002f38:	bfd5                	j	80002f2c <sys_sbrk+0x3c>

0000000080002f3a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f3a:	7139                	addi	sp,sp,-64
    80002f3c:	fc06                	sd	ra,56(sp)
    80002f3e:	f822                	sd	s0,48(sp)
    80002f40:	f426                	sd	s1,40(sp)
    80002f42:	f04a                	sd	s2,32(sp)
    80002f44:	ec4e                	sd	s3,24(sp)
    80002f46:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f48:	fcc40593          	addi	a1,s0,-52
    80002f4c:	4501                	li	a0,0
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	e2a080e7          	jalr	-470(ra) # 80002d78 <argint>
    return -1;
    80002f56:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f58:	06054563          	bltz	a0,80002fc2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f5c:	00020517          	auipc	a0,0x20
    80002f60:	15c50513          	addi	a0,a0,348 # 800230b8 <tickslock>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	c72080e7          	jalr	-910(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002f6c:	00006917          	auipc	s2,0x6
    80002f70:	0c492903          	lw	s2,196(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f74:	fcc42783          	lw	a5,-52(s0)
    80002f78:	cf85                	beqz	a5,80002fb0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f7a:	00020997          	auipc	s3,0x20
    80002f7e:	13e98993          	addi	s3,s3,318 # 800230b8 <tickslock>
    80002f82:	00006497          	auipc	s1,0x6
    80002f86:	0ae48493          	addi	s1,s1,174 # 80009030 <ticks>
    if(myproc()->killed){
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	afc080e7          	jalr	-1284(ra) # 80001a86 <myproc>
    80002f92:	591c                	lw	a5,48(a0)
    80002f94:	ef9d                	bnez	a5,80002fd2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f96:	85ce                	mv	a1,s3
    80002f98:	8526                	mv	a0,s1
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	3b0080e7          	jalr	944(ra) # 8000234a <sleep>
  while(ticks - ticks0 < n){
    80002fa2:	409c                	lw	a5,0(s1)
    80002fa4:	412787bb          	subw	a5,a5,s2
    80002fa8:	fcc42703          	lw	a4,-52(s0)
    80002fac:	fce7efe3          	bltu	a5,a4,80002f8a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fb0:	00020517          	auipc	a0,0x20
    80002fb4:	10850513          	addi	a0,a0,264 # 800230b8 <tickslock>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	cd2080e7          	jalr	-814(ra) # 80000c8a <release>
  return 0;
    80002fc0:	4781                	li	a5,0
}
    80002fc2:	853e                	mv	a0,a5
    80002fc4:	70e2                	ld	ra,56(sp)
    80002fc6:	7442                	ld	s0,48(sp)
    80002fc8:	74a2                	ld	s1,40(sp)
    80002fca:	7902                	ld	s2,32(sp)
    80002fcc:	69e2                	ld	s3,24(sp)
    80002fce:	6121                	addi	sp,sp,64
    80002fd0:	8082                	ret
      release(&tickslock);
    80002fd2:	00020517          	auipc	a0,0x20
    80002fd6:	0e650513          	addi	a0,a0,230 # 800230b8 <tickslock>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	cb0080e7          	jalr	-848(ra) # 80000c8a <release>
      return -1;
    80002fe2:	57fd                	li	a5,-1
    80002fe4:	bff9                	j	80002fc2 <sys_sleep+0x88>

0000000080002fe6 <sys_kill>:

uint64
sys_kill(void)
{
    80002fe6:	1101                	addi	sp,sp,-32
    80002fe8:	ec06                	sd	ra,24(sp)
    80002fea:	e822                	sd	s0,16(sp)
    80002fec:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fee:	fec40593          	addi	a1,s0,-20
    80002ff2:	4501                	li	a0,0
    80002ff4:	00000097          	auipc	ra,0x0
    80002ff8:	d84080e7          	jalr	-636(ra) # 80002d78 <argint>
    80002ffc:	87aa                	mv	a5,a0
    return -1;
    80002ffe:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003000:	0007c863          	bltz	a5,80003010 <sys_kill+0x2a>
  return kill(pid);
    80003004:	fec42503          	lw	a0,-20(s0)
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	532080e7          	jalr	1330(ra) # 8000253a <kill>
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	6105                	addi	sp,sp,32
    80003016:	8082                	ret

0000000080003018 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003022:	00020517          	auipc	a0,0x20
    80003026:	09650513          	addi	a0,a0,150 # 800230b8 <tickslock>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	bac080e7          	jalr	-1108(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003032:	00006497          	auipc	s1,0x6
    80003036:	ffe4a483          	lw	s1,-2(s1) # 80009030 <ticks>
  release(&tickslock);
    8000303a:	00020517          	auipc	a0,0x20
    8000303e:	07e50513          	addi	a0,a0,126 # 800230b8 <tickslock>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
  return xticks;
}
    8000304a:	02049513          	slli	a0,s1,0x20
    8000304e:	9101                	srli	a0,a0,0x20
    80003050:	60e2                	ld	ra,24(sp)
    80003052:	6442                	ld	s0,16(sp)
    80003054:	64a2                	ld	s1,8(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret

000000008000305a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000305a:	7179                	addi	sp,sp,-48
    8000305c:	f406                	sd	ra,40(sp)
    8000305e:	f022                	sd	s0,32(sp)
    80003060:	ec26                	sd	s1,24(sp)
    80003062:	e84a                	sd	s2,16(sp)
    80003064:	e44e                	sd	s3,8(sp)
    80003066:	e052                	sd	s4,0(sp)
    80003068:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000306a:	00005597          	auipc	a1,0x5
    8000306e:	4d658593          	addi	a1,a1,1238 # 80008540 <syscalls+0xc0>
    80003072:	00020517          	auipc	a0,0x20
    80003076:	05e50513          	addi	a0,a0,94 # 800230d0 <bcache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	acc080e7          	jalr	-1332(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003082:	00028797          	auipc	a5,0x28
    80003086:	04e78793          	addi	a5,a5,78 # 8002b0d0 <bcache+0x8000>
    8000308a:	00028717          	auipc	a4,0x28
    8000308e:	2ae70713          	addi	a4,a4,686 # 8002b338 <bcache+0x8268>
    80003092:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003096:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000309a:	00020497          	auipc	s1,0x20
    8000309e:	04e48493          	addi	s1,s1,78 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    800030a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030a6:	00005a17          	auipc	s4,0x5
    800030aa:	4a2a0a13          	addi	s4,s4,1186 # 80008548 <syscalls+0xc8>
    b->next = bcache.head.next;
    800030ae:	2b893783          	ld	a5,696(s2)
    800030b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030b8:	85d2                	mv	a1,s4
    800030ba:	01048513          	addi	a0,s1,16
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	4da080e7          	jalr	1242(ra) # 80004598 <initsleeplock>
    bcache.head.next->prev = b;
    800030c6:	2b893783          	ld	a5,696(s2)
    800030ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d0:	45848493          	addi	s1,s1,1112
    800030d4:	fd349de3          	bne	s1,s3,800030ae <binit+0x54>
  }
}
    800030d8:	70a2                	ld	ra,40(sp)
    800030da:	7402                	ld	s0,32(sp)
    800030dc:	64e2                	ld	s1,24(sp)
    800030de:	6942                	ld	s2,16(sp)
    800030e0:	69a2                	ld	s3,8(sp)
    800030e2:	6a02                	ld	s4,0(sp)
    800030e4:	6145                	addi	sp,sp,48
    800030e6:	8082                	ret

00000000800030e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030e8:	7179                	addi	sp,sp,-48
    800030ea:	f406                	sd	ra,40(sp)
    800030ec:	f022                	sd	s0,32(sp)
    800030ee:	ec26                	sd	s1,24(sp)
    800030f0:	e84a                	sd	s2,16(sp)
    800030f2:	e44e                	sd	s3,8(sp)
    800030f4:	1800                	addi	s0,sp,48
    800030f6:	89aa                	mv	s3,a0
    800030f8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030fa:	00020517          	auipc	a0,0x20
    800030fe:	fd650513          	addi	a0,a0,-42 # 800230d0 <bcache>
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000310a:	00028497          	auipc	s1,0x28
    8000310e:	27e4b483          	ld	s1,638(s1) # 8002b388 <bcache+0x82b8>
    80003112:	00028797          	auipc	a5,0x28
    80003116:	22678793          	addi	a5,a5,550 # 8002b338 <bcache+0x8268>
    8000311a:	02f48f63          	beq	s1,a5,80003158 <bread+0x70>
    8000311e:	873e                	mv	a4,a5
    80003120:	a021                	j	80003128 <bread+0x40>
    80003122:	68a4                	ld	s1,80(s1)
    80003124:	02e48a63          	beq	s1,a4,80003158 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003128:	449c                	lw	a5,8(s1)
    8000312a:	ff379ce3          	bne	a5,s3,80003122 <bread+0x3a>
    8000312e:	44dc                	lw	a5,12(s1)
    80003130:	ff2799e3          	bne	a5,s2,80003122 <bread+0x3a>
      b->refcnt++;
    80003134:	40bc                	lw	a5,64(s1)
    80003136:	2785                	addiw	a5,a5,1
    80003138:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000313a:	00020517          	auipc	a0,0x20
    8000313e:	f9650513          	addi	a0,a0,-106 # 800230d0 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	b48080e7          	jalr	-1208(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000314a:	01048513          	addi	a0,s1,16
    8000314e:	00001097          	auipc	ra,0x1
    80003152:	484080e7          	jalr	1156(ra) # 800045d2 <acquiresleep>
      return b;
    80003156:	a8b9                	j	800031b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003158:	00028497          	auipc	s1,0x28
    8000315c:	2284b483          	ld	s1,552(s1) # 8002b380 <bcache+0x82b0>
    80003160:	00028797          	auipc	a5,0x28
    80003164:	1d878793          	addi	a5,a5,472 # 8002b338 <bcache+0x8268>
    80003168:	00f48863          	beq	s1,a5,80003178 <bread+0x90>
    8000316c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000316e:	40bc                	lw	a5,64(s1)
    80003170:	cf81                	beqz	a5,80003188 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003172:	64a4                	ld	s1,72(s1)
    80003174:	fee49de3          	bne	s1,a4,8000316e <bread+0x86>
  panic("bget: no buffers");
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	3d850513          	addi	a0,a0,984 # 80008550 <syscalls+0xd0>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3b0080e7          	jalr	944(ra) # 80000530 <panic>
      b->dev = dev;
    80003188:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000318c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003190:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003194:	4785                	li	a5,1
    80003196:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003198:	00020517          	auipc	a0,0x20
    8000319c:	f3850513          	addi	a0,a0,-200 # 800230d0 <bcache>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	aea080e7          	jalr	-1302(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031a8:	01048513          	addi	a0,s1,16
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	426080e7          	jalr	1062(ra) # 800045d2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031b4:	409c                	lw	a5,0(s1)
    800031b6:	cb89                	beqz	a5,800031c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031b8:	8526                	mv	a0,s1
    800031ba:	70a2                	ld	ra,40(sp)
    800031bc:	7402                	ld	s0,32(sp)
    800031be:	64e2                	ld	s1,24(sp)
    800031c0:	6942                	ld	s2,16(sp)
    800031c2:	69a2                	ld	s3,8(sp)
    800031c4:	6145                	addi	sp,sp,48
    800031c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800031c8:	4581                	li	a1,0
    800031ca:	8526                	mv	a0,s1
    800031cc:	00003097          	auipc	ra,0x3
    800031d0:	30a080e7          	jalr	778(ra) # 800064d6 <virtio_disk_rw>
    b->valid = 1;
    800031d4:	4785                	li	a5,1
    800031d6:	c09c                	sw	a5,0(s1)
  return b;
    800031d8:	b7c5                	j	800031b8 <bread+0xd0>

00000000800031da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	1000                	addi	s0,sp,32
    800031e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e6:	0541                	addi	a0,a0,16
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	484080e7          	jalr	1156(ra) # 8000466c <holdingsleep>
    800031f0:	cd01                	beqz	a0,80003208 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031f2:	4585                	li	a1,1
    800031f4:	8526                	mv	a0,s1
    800031f6:	00003097          	auipc	ra,0x3
    800031fa:	2e0080e7          	jalr	736(ra) # 800064d6 <virtio_disk_rw>
}
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	64a2                	ld	s1,8(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret
    panic("bwrite");
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	36050513          	addi	a0,a0,864 # 80008568 <syscalls+0xe8>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	320080e7          	jalr	800(ra) # 80000530 <panic>

0000000080003218 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003218:	1101                	addi	sp,sp,-32
    8000321a:	ec06                	sd	ra,24(sp)
    8000321c:	e822                	sd	s0,16(sp)
    8000321e:	e426                	sd	s1,8(sp)
    80003220:	e04a                	sd	s2,0(sp)
    80003222:	1000                	addi	s0,sp,32
    80003224:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003226:	01050913          	addi	s2,a0,16
    8000322a:	854a                	mv	a0,s2
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	440080e7          	jalr	1088(ra) # 8000466c <holdingsleep>
    80003234:	c92d                	beqz	a0,800032a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	3f0080e7          	jalr	1008(ra) # 80004628 <releasesleep>

  acquire(&bcache.lock);
    80003240:	00020517          	auipc	a0,0x20
    80003244:	e9050513          	addi	a0,a0,-368 # 800230d0 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	98e080e7          	jalr	-1650(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003250:	40bc                	lw	a5,64(s1)
    80003252:	37fd                	addiw	a5,a5,-1
    80003254:	0007871b          	sext.w	a4,a5
    80003258:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000325a:	eb05                	bnez	a4,8000328a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000325c:	68bc                	ld	a5,80(s1)
    8000325e:	64b8                	ld	a4,72(s1)
    80003260:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003262:	64bc                	ld	a5,72(s1)
    80003264:	68b8                	ld	a4,80(s1)
    80003266:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003268:	00028797          	auipc	a5,0x28
    8000326c:	e6878793          	addi	a5,a5,-408 # 8002b0d0 <bcache+0x8000>
    80003270:	2b87b703          	ld	a4,696(a5)
    80003274:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003276:	00028717          	auipc	a4,0x28
    8000327a:	0c270713          	addi	a4,a4,194 # 8002b338 <bcache+0x8268>
    8000327e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003280:	2b87b703          	ld	a4,696(a5)
    80003284:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003286:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000328a:	00020517          	auipc	a0,0x20
    8000328e:	e4650513          	addi	a0,a0,-442 # 800230d0 <bcache>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	9f8080e7          	jalr	-1544(ra) # 80000c8a <release>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	64a2                	ld	s1,8(sp)
    800032a0:	6902                	ld	s2,0(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret
    panic("brelse");
    800032a6:	00005517          	auipc	a0,0x5
    800032aa:	2ca50513          	addi	a0,a0,714 # 80008570 <syscalls+0xf0>
    800032ae:	ffffd097          	auipc	ra,0xffffd
    800032b2:	282080e7          	jalr	642(ra) # 80000530 <panic>

00000000800032b6 <bpin>:

void
bpin(struct buf *b) {
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c2:	00020517          	auipc	a0,0x20
    800032c6:	e0e50513          	addi	a0,a0,-498 # 800230d0 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	90c080e7          	jalr	-1780(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800032d2:	40bc                	lw	a5,64(s1)
    800032d4:	2785                	addiw	a5,a5,1
    800032d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d8:	00020517          	auipc	a0,0x20
    800032dc:	df850513          	addi	a0,a0,-520 # 800230d0 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <bunpin>:

void
bunpin(struct buf *b) {
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032fe:	00020517          	auipc	a0,0x20
    80003302:	dd250513          	addi	a0,a0,-558 # 800230d0 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	8d0080e7          	jalr	-1840(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000330e:	40bc                	lw	a5,64(s1)
    80003310:	37fd                	addiw	a5,a5,-1
    80003312:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003314:	00020517          	auipc	a0,0x20
    80003318:	dbc50513          	addi	a0,a0,-580 # 800230d0 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	96e080e7          	jalr	-1682(ra) # 80000c8a <release>
}
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	64a2                	ld	s1,8(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret

000000008000332e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	e04a                	sd	s2,0(sp)
    80003338:	1000                	addi	s0,sp,32
    8000333a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000333c:	00d5d59b          	srliw	a1,a1,0xd
    80003340:	00028797          	auipc	a5,0x28
    80003344:	46c7a783          	lw	a5,1132(a5) # 8002b7ac <sb+0x1c>
    80003348:	9dbd                	addw	a1,a1,a5
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	d9e080e7          	jalr	-610(ra) # 800030e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003352:	0074f713          	andi	a4,s1,7
    80003356:	4785                	li	a5,1
    80003358:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000335c:	14ce                	slli	s1,s1,0x33
    8000335e:	90d9                	srli	s1,s1,0x36
    80003360:	00950733          	add	a4,a0,s1
    80003364:	05874703          	lbu	a4,88(a4)
    80003368:	00e7f6b3          	and	a3,a5,a4
    8000336c:	c69d                	beqz	a3,8000339a <bfree+0x6c>
    8000336e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003370:	94aa                	add	s1,s1,a0
    80003372:	fff7c793          	not	a5,a5
    80003376:	8ff9                	and	a5,a5,a4
    80003378:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	12e080e7          	jalr	302(ra) # 800044aa <log_write>
  brelse(bp);
    80003384:	854a                	mv	a0,s2
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e92080e7          	jalr	-366(ra) # 80003218 <brelse>
}
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	64a2                	ld	s1,8(sp)
    80003394:	6902                	ld	s2,0(sp)
    80003396:	6105                	addi	sp,sp,32
    80003398:	8082                	ret
    panic("freeing free block");
    8000339a:	00005517          	auipc	a0,0x5
    8000339e:	1de50513          	addi	a0,a0,478 # 80008578 <syscalls+0xf8>
    800033a2:	ffffd097          	auipc	ra,0xffffd
    800033a6:	18e080e7          	jalr	398(ra) # 80000530 <panic>

00000000800033aa <balloc>:
{
    800033aa:	711d                	addi	sp,sp,-96
    800033ac:	ec86                	sd	ra,88(sp)
    800033ae:	e8a2                	sd	s0,80(sp)
    800033b0:	e4a6                	sd	s1,72(sp)
    800033b2:	e0ca                	sd	s2,64(sp)
    800033b4:	fc4e                	sd	s3,56(sp)
    800033b6:	f852                	sd	s4,48(sp)
    800033b8:	f456                	sd	s5,40(sp)
    800033ba:	f05a                	sd	s6,32(sp)
    800033bc:	ec5e                	sd	s7,24(sp)
    800033be:	e862                	sd	s8,16(sp)
    800033c0:	e466                	sd	s9,8(sp)
    800033c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033c4:	00028797          	auipc	a5,0x28
    800033c8:	3d07a783          	lw	a5,976(a5) # 8002b794 <sb+0x4>
    800033cc:	cbd1                	beqz	a5,80003460 <balloc+0xb6>
    800033ce:	8baa                	mv	s7,a0
    800033d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033d2:	00028b17          	auipc	s6,0x28
    800033d6:	3beb0b13          	addi	s6,s6,958 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033e0:	6c89                	lui	s9,0x2
    800033e2:	a831                	j	800033fe <balloc+0x54>
    brelse(bp);
    800033e4:	854a                	mv	a0,s2
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	e32080e7          	jalr	-462(ra) # 80003218 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033ee:	015c87bb          	addw	a5,s9,s5
    800033f2:	00078a9b          	sext.w	s5,a5
    800033f6:	004b2703          	lw	a4,4(s6)
    800033fa:	06eaf363          	bgeu	s5,a4,80003460 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033fe:	41fad79b          	sraiw	a5,s5,0x1f
    80003402:	0137d79b          	srliw	a5,a5,0x13
    80003406:	015787bb          	addw	a5,a5,s5
    8000340a:	40d7d79b          	sraiw	a5,a5,0xd
    8000340e:	01cb2583          	lw	a1,28(s6)
    80003412:	9dbd                	addw	a1,a1,a5
    80003414:	855e                	mv	a0,s7
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	cd2080e7          	jalr	-814(ra) # 800030e8 <bread>
    8000341e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003420:	004b2503          	lw	a0,4(s6)
    80003424:	000a849b          	sext.w	s1,s5
    80003428:	8662                	mv	a2,s8
    8000342a:	faa4fde3          	bgeu	s1,a0,800033e4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000342e:	41f6579b          	sraiw	a5,a2,0x1f
    80003432:	01d7d69b          	srliw	a3,a5,0x1d
    80003436:	00c6873b          	addw	a4,a3,a2
    8000343a:	00777793          	andi	a5,a4,7
    8000343e:	9f95                	subw	a5,a5,a3
    80003440:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003444:	4037571b          	sraiw	a4,a4,0x3
    80003448:	00e906b3          	add	a3,s2,a4
    8000344c:	0586c683          	lbu	a3,88(a3)
    80003450:	00d7f5b3          	and	a1,a5,a3
    80003454:	cd91                	beqz	a1,80003470 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003456:	2605                	addiw	a2,a2,1
    80003458:	2485                	addiw	s1,s1,1
    8000345a:	fd4618e3          	bne	a2,s4,8000342a <balloc+0x80>
    8000345e:	b759                	j	800033e4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003460:	00005517          	auipc	a0,0x5
    80003464:	13050513          	addi	a0,a0,304 # 80008590 <syscalls+0x110>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	0c8080e7          	jalr	200(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003470:	974a                	add	a4,a4,s2
    80003472:	8fd5                	or	a5,a5,a3
    80003474:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003478:	854a                	mv	a0,s2
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	030080e7          	jalr	48(ra) # 800044aa <log_write>
        brelse(bp);
    80003482:	854a                	mv	a0,s2
    80003484:	00000097          	auipc	ra,0x0
    80003488:	d94080e7          	jalr	-620(ra) # 80003218 <brelse>
  bp = bread(dev, bno);
    8000348c:	85a6                	mv	a1,s1
    8000348e:	855e                	mv	a0,s7
    80003490:	00000097          	auipc	ra,0x0
    80003494:	c58080e7          	jalr	-936(ra) # 800030e8 <bread>
    80003498:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000349a:	40000613          	li	a2,1024
    8000349e:	4581                	li	a1,0
    800034a0:	05850513          	addi	a0,a0,88
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	82e080e7          	jalr	-2002(ra) # 80000cd2 <memset>
  log_write(bp);
    800034ac:	854a                	mv	a0,s2
    800034ae:	00001097          	auipc	ra,0x1
    800034b2:	ffc080e7          	jalr	-4(ra) # 800044aa <log_write>
  brelse(bp);
    800034b6:	854a                	mv	a0,s2
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	d60080e7          	jalr	-672(ra) # 80003218 <brelse>
}
    800034c0:	8526                	mv	a0,s1
    800034c2:	60e6                	ld	ra,88(sp)
    800034c4:	6446                	ld	s0,80(sp)
    800034c6:	64a6                	ld	s1,72(sp)
    800034c8:	6906                	ld	s2,64(sp)
    800034ca:	79e2                	ld	s3,56(sp)
    800034cc:	7a42                	ld	s4,48(sp)
    800034ce:	7aa2                	ld	s5,40(sp)
    800034d0:	7b02                	ld	s6,32(sp)
    800034d2:	6be2                	ld	s7,24(sp)
    800034d4:	6c42                	ld	s8,16(sp)
    800034d6:	6ca2                	ld	s9,8(sp)
    800034d8:	6125                	addi	sp,sp,96
    800034da:	8082                	ret

00000000800034dc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	e052                	sd	s4,0(sp)
    800034ea:	1800                	addi	s0,sp,48
    800034ec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034ee:	47ad                	li	a5,11
    800034f0:	04b7fe63          	bgeu	a5,a1,8000354c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034f4:	ff45849b          	addiw	s1,a1,-12
    800034f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034fc:	0ff00793          	li	a5,255
    80003500:	0ae7e363          	bltu	a5,a4,800035a6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003504:	08052583          	lw	a1,128(a0)
    80003508:	c5ad                	beqz	a1,80003572 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000350a:	00092503          	lw	a0,0(s2)
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	bda080e7          	jalr	-1062(ra) # 800030e8 <bread>
    80003516:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003518:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000351c:	02049593          	slli	a1,s1,0x20
    80003520:	9181                	srli	a1,a1,0x20
    80003522:	058a                	slli	a1,a1,0x2
    80003524:	00b784b3          	add	s1,a5,a1
    80003528:	0004a983          	lw	s3,0(s1)
    8000352c:	04098d63          	beqz	s3,80003586 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003530:	8552                	mv	a0,s4
    80003532:	00000097          	auipc	ra,0x0
    80003536:	ce6080e7          	jalr	-794(ra) # 80003218 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000353a:	854e                	mv	a0,s3
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6942                	ld	s2,16(sp)
    80003544:	69a2                	ld	s3,8(sp)
    80003546:	6a02                	ld	s4,0(sp)
    80003548:	6145                	addi	sp,sp,48
    8000354a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000354c:	02059493          	slli	s1,a1,0x20
    80003550:	9081                	srli	s1,s1,0x20
    80003552:	048a                	slli	s1,s1,0x2
    80003554:	94aa                	add	s1,s1,a0
    80003556:	0504a983          	lw	s3,80(s1)
    8000355a:	fe0990e3          	bnez	s3,8000353a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000355e:	4108                	lw	a0,0(a0)
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e4a080e7          	jalr	-438(ra) # 800033aa <balloc>
    80003568:	0005099b          	sext.w	s3,a0
    8000356c:	0534a823          	sw	s3,80(s1)
    80003570:	b7e9                	j	8000353a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003572:	4108                	lw	a0,0(a0)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	e36080e7          	jalr	-458(ra) # 800033aa <balloc>
    8000357c:	0005059b          	sext.w	a1,a0
    80003580:	08b92023          	sw	a1,128(s2)
    80003584:	b759                	j	8000350a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003586:	00092503          	lw	a0,0(s2)
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	e20080e7          	jalr	-480(ra) # 800033aa <balloc>
    80003592:	0005099b          	sext.w	s3,a0
    80003596:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000359a:	8552                	mv	a0,s4
    8000359c:	00001097          	auipc	ra,0x1
    800035a0:	f0e080e7          	jalr	-242(ra) # 800044aa <log_write>
    800035a4:	b771                	j	80003530 <bmap+0x54>
  panic("bmap: out of range");
    800035a6:	00005517          	auipc	a0,0x5
    800035aa:	00250513          	addi	a0,a0,2 # 800085a8 <syscalls+0x128>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	f82080e7          	jalr	-126(ra) # 80000530 <panic>

00000000800035b6 <iget>:
{
    800035b6:	7179                	addi	sp,sp,-48
    800035b8:	f406                	sd	ra,40(sp)
    800035ba:	f022                	sd	s0,32(sp)
    800035bc:	ec26                	sd	s1,24(sp)
    800035be:	e84a                	sd	s2,16(sp)
    800035c0:	e44e                	sd	s3,8(sp)
    800035c2:	e052                	sd	s4,0(sp)
    800035c4:	1800                	addi	s0,sp,48
    800035c6:	89aa                	mv	s3,a0
    800035c8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035ca:	00028517          	auipc	a0,0x28
    800035ce:	1e650513          	addi	a0,a0,486 # 8002b7b0 <icache>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	604080e7          	jalr	1540(ra) # 80000bd6 <acquire>
  empty = 0;
    800035da:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035dc:	00028497          	auipc	s1,0x28
    800035e0:	1ec48493          	addi	s1,s1,492 # 8002b7c8 <icache+0x18>
    800035e4:	0002a697          	auipc	a3,0x2a
    800035e8:	c7468693          	addi	a3,a3,-908 # 8002d258 <log>
    800035ec:	a039                	j	800035fa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ee:	02090b63          	beqz	s2,80003624 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035f2:	08848493          	addi	s1,s1,136
    800035f6:	02d48a63          	beq	s1,a3,8000362a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035fa:	449c                	lw	a5,8(s1)
    800035fc:	fef059e3          	blez	a5,800035ee <iget+0x38>
    80003600:	4098                	lw	a4,0(s1)
    80003602:	ff3716e3          	bne	a4,s3,800035ee <iget+0x38>
    80003606:	40d8                	lw	a4,4(s1)
    80003608:	ff4713e3          	bne	a4,s4,800035ee <iget+0x38>
      ip->ref++;
    8000360c:	2785                	addiw	a5,a5,1
    8000360e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003610:	00028517          	auipc	a0,0x28
    80003614:	1a050513          	addi	a0,a0,416 # 8002b7b0 <icache>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	672080e7          	jalr	1650(ra) # 80000c8a <release>
      return ip;
    80003620:	8926                	mv	s2,s1
    80003622:	a03d                	j	80003650 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003624:	f7f9                	bnez	a5,800035f2 <iget+0x3c>
    80003626:	8926                	mv	s2,s1
    80003628:	b7e9                	j	800035f2 <iget+0x3c>
  if(empty == 0)
    8000362a:	02090c63          	beqz	s2,80003662 <iget+0xac>
  ip->dev = dev;
    8000362e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003632:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003636:	4785                	li	a5,1
    80003638:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000363c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003640:	00028517          	auipc	a0,0x28
    80003644:	17050513          	addi	a0,a0,368 # 8002b7b0 <icache>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	642080e7          	jalr	1602(ra) # 80000c8a <release>
}
    80003650:	854a                	mv	a0,s2
    80003652:	70a2                	ld	ra,40(sp)
    80003654:	7402                	ld	s0,32(sp)
    80003656:	64e2                	ld	s1,24(sp)
    80003658:	6942                	ld	s2,16(sp)
    8000365a:	69a2                	ld	s3,8(sp)
    8000365c:	6a02                	ld	s4,0(sp)
    8000365e:	6145                	addi	sp,sp,48
    80003660:	8082                	ret
    panic("iget: no inodes");
    80003662:	00005517          	auipc	a0,0x5
    80003666:	f5e50513          	addi	a0,a0,-162 # 800085c0 <syscalls+0x140>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	ec6080e7          	jalr	-314(ra) # 80000530 <panic>

0000000080003672 <fsinit>:
fsinit(int dev) {
    80003672:	7179                	addi	sp,sp,-48
    80003674:	f406                	sd	ra,40(sp)
    80003676:	f022                	sd	s0,32(sp)
    80003678:	ec26                	sd	s1,24(sp)
    8000367a:	e84a                	sd	s2,16(sp)
    8000367c:	e44e                	sd	s3,8(sp)
    8000367e:	1800                	addi	s0,sp,48
    80003680:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003682:	4585                	li	a1,1
    80003684:	00000097          	auipc	ra,0x0
    80003688:	a64080e7          	jalr	-1436(ra) # 800030e8 <bread>
    8000368c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000368e:	00028997          	auipc	s3,0x28
    80003692:	10298993          	addi	s3,s3,258 # 8002b790 <sb>
    80003696:	02000613          	li	a2,32
    8000369a:	05850593          	addi	a1,a0,88
    8000369e:	854e                	mv	a0,s3
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	692080e7          	jalr	1682(ra) # 80000d32 <memmove>
  brelse(bp);
    800036a8:	8526                	mv	a0,s1
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	b6e080e7          	jalr	-1170(ra) # 80003218 <brelse>
  if(sb.magic != FSMAGIC)
    800036b2:	0009a703          	lw	a4,0(s3)
    800036b6:	102037b7          	lui	a5,0x10203
    800036ba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036be:	02f71263          	bne	a4,a5,800036e2 <fsinit+0x70>
  initlog(dev, &sb);
    800036c2:	00028597          	auipc	a1,0x28
    800036c6:	0ce58593          	addi	a1,a1,206 # 8002b790 <sb>
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	b62080e7          	jalr	-1182(ra) # 8000422e <initlog>
}
    800036d4:	70a2                	ld	ra,40(sp)
    800036d6:	7402                	ld	s0,32(sp)
    800036d8:	64e2                	ld	s1,24(sp)
    800036da:	6942                	ld	s2,16(sp)
    800036dc:	69a2                	ld	s3,8(sp)
    800036de:	6145                	addi	sp,sp,48
    800036e0:	8082                	ret
    panic("invalid file system");
    800036e2:	00005517          	auipc	a0,0x5
    800036e6:	eee50513          	addi	a0,a0,-274 # 800085d0 <syscalls+0x150>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	e46080e7          	jalr	-442(ra) # 80000530 <panic>

00000000800036f2 <iinit>:
{
    800036f2:	7179                	addi	sp,sp,-48
    800036f4:	f406                	sd	ra,40(sp)
    800036f6:	f022                	sd	s0,32(sp)
    800036f8:	ec26                	sd	s1,24(sp)
    800036fa:	e84a                	sd	s2,16(sp)
    800036fc:	e44e                	sd	s3,8(sp)
    800036fe:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003700:	00005597          	auipc	a1,0x5
    80003704:	ee858593          	addi	a1,a1,-280 # 800085e8 <syscalls+0x168>
    80003708:	00028517          	auipc	a0,0x28
    8000370c:	0a850513          	addi	a0,a0,168 # 8002b7b0 <icache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	436080e7          	jalr	1078(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003718:	00028497          	auipc	s1,0x28
    8000371c:	0c048493          	addi	s1,s1,192 # 8002b7d8 <icache+0x28>
    80003720:	0002a997          	auipc	s3,0x2a
    80003724:	b4898993          	addi	s3,s3,-1208 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003728:	00005917          	auipc	s2,0x5
    8000372c:	ec890913          	addi	s2,s2,-312 # 800085f0 <syscalls+0x170>
    80003730:	85ca                	mv	a1,s2
    80003732:	8526                	mv	a0,s1
    80003734:	00001097          	auipc	ra,0x1
    80003738:	e64080e7          	jalr	-412(ra) # 80004598 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000373c:	08848493          	addi	s1,s1,136
    80003740:	ff3498e3          	bne	s1,s3,80003730 <iinit+0x3e>
}
    80003744:	70a2                	ld	ra,40(sp)
    80003746:	7402                	ld	s0,32(sp)
    80003748:	64e2                	ld	s1,24(sp)
    8000374a:	6942                	ld	s2,16(sp)
    8000374c:	69a2                	ld	s3,8(sp)
    8000374e:	6145                	addi	sp,sp,48
    80003750:	8082                	ret

0000000080003752 <ialloc>:
{
    80003752:	715d                	addi	sp,sp,-80
    80003754:	e486                	sd	ra,72(sp)
    80003756:	e0a2                	sd	s0,64(sp)
    80003758:	fc26                	sd	s1,56(sp)
    8000375a:	f84a                	sd	s2,48(sp)
    8000375c:	f44e                	sd	s3,40(sp)
    8000375e:	f052                	sd	s4,32(sp)
    80003760:	ec56                	sd	s5,24(sp)
    80003762:	e85a                	sd	s6,16(sp)
    80003764:	e45e                	sd	s7,8(sp)
    80003766:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003768:	00028717          	auipc	a4,0x28
    8000376c:	03472703          	lw	a4,52(a4) # 8002b79c <sb+0xc>
    80003770:	4785                	li	a5,1
    80003772:	04e7fa63          	bgeu	a5,a4,800037c6 <ialloc+0x74>
    80003776:	8aaa                	mv	s5,a0
    80003778:	8bae                	mv	s7,a1
    8000377a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000377c:	00028a17          	auipc	s4,0x28
    80003780:	014a0a13          	addi	s4,s4,20 # 8002b790 <sb>
    80003784:	00048b1b          	sext.w	s6,s1
    80003788:	0044d593          	srli	a1,s1,0x4
    8000378c:	018a2783          	lw	a5,24(s4)
    80003790:	9dbd                	addw	a1,a1,a5
    80003792:	8556                	mv	a0,s5
    80003794:	00000097          	auipc	ra,0x0
    80003798:	954080e7          	jalr	-1708(ra) # 800030e8 <bread>
    8000379c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000379e:	05850993          	addi	s3,a0,88
    800037a2:	00f4f793          	andi	a5,s1,15
    800037a6:	079a                	slli	a5,a5,0x6
    800037a8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037aa:	00099783          	lh	a5,0(s3)
    800037ae:	c785                	beqz	a5,800037d6 <ialloc+0x84>
    brelse(bp);
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	a68080e7          	jalr	-1432(ra) # 80003218 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b8:	0485                	addi	s1,s1,1
    800037ba:	00ca2703          	lw	a4,12(s4)
    800037be:	0004879b          	sext.w	a5,s1
    800037c2:	fce7e1e3          	bltu	a5,a4,80003784 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	e3250513          	addi	a0,a0,-462 # 800085f8 <syscalls+0x178>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d62080e7          	jalr	-670(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800037d6:	04000613          	li	a2,64
    800037da:	4581                	li	a1,0
    800037dc:	854e                	mv	a0,s3
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4f4080e7          	jalr	1268(ra) # 80000cd2 <memset>
      dip->type = type;
    800037e6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	cbe080e7          	jalr	-834(ra) # 800044aa <log_write>
      brelse(bp);
    800037f4:	854a                	mv	a0,s2
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	a22080e7          	jalr	-1502(ra) # 80003218 <brelse>
      return iget(dev, inum);
    800037fe:	85da                	mv	a1,s6
    80003800:	8556                	mv	a0,s5
    80003802:	00000097          	auipc	ra,0x0
    80003806:	db4080e7          	jalr	-588(ra) # 800035b6 <iget>
}
    8000380a:	60a6                	ld	ra,72(sp)
    8000380c:	6406                	ld	s0,64(sp)
    8000380e:	74e2                	ld	s1,56(sp)
    80003810:	7942                	ld	s2,48(sp)
    80003812:	79a2                	ld	s3,40(sp)
    80003814:	7a02                	ld	s4,32(sp)
    80003816:	6ae2                	ld	s5,24(sp)
    80003818:	6b42                	ld	s6,16(sp)
    8000381a:	6ba2                	ld	s7,8(sp)
    8000381c:	6161                	addi	sp,sp,80
    8000381e:	8082                	ret

0000000080003820 <iupdate>:
{
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	e04a                	sd	s2,0(sp)
    8000382a:	1000                	addi	s0,sp,32
    8000382c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000382e:	415c                	lw	a5,4(a0)
    80003830:	0047d79b          	srliw	a5,a5,0x4
    80003834:	00028597          	auipc	a1,0x28
    80003838:	f745a583          	lw	a1,-140(a1) # 8002b7a8 <sb+0x18>
    8000383c:	9dbd                	addw	a1,a1,a5
    8000383e:	4108                	lw	a0,0(a0)
    80003840:	00000097          	auipc	ra,0x0
    80003844:	8a8080e7          	jalr	-1880(ra) # 800030e8 <bread>
    80003848:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000384a:	05850793          	addi	a5,a0,88
    8000384e:	40c8                	lw	a0,4(s1)
    80003850:	893d                	andi	a0,a0,15
    80003852:	051a                	slli	a0,a0,0x6
    80003854:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003856:	04449703          	lh	a4,68(s1)
    8000385a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000385e:	04649703          	lh	a4,70(s1)
    80003862:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003866:	04849703          	lh	a4,72(s1)
    8000386a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000386e:	04a49703          	lh	a4,74(s1)
    80003872:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003876:	44f8                	lw	a4,76(s1)
    80003878:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000387a:	03400613          	li	a2,52
    8000387e:	05048593          	addi	a1,s1,80
    80003882:	0531                	addi	a0,a0,12
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	4ae080e7          	jalr	1198(ra) # 80000d32 <memmove>
  log_write(bp);
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c1c080e7          	jalr	-996(ra) # 800044aa <log_write>
  brelse(bp);
    80003896:	854a                	mv	a0,s2
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	980080e7          	jalr	-1664(ra) # 80003218 <brelse>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret

00000000800038ac <idup>:
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	1000                	addi	s0,sp,32
    800038b6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038b8:	00028517          	auipc	a0,0x28
    800038bc:	ef850513          	addi	a0,a0,-264 # 8002b7b0 <icache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	316080e7          	jalr	790(ra) # 80000bd6 <acquire>
  ip->ref++;
    800038c8:	449c                	lw	a5,8(s1)
    800038ca:	2785                	addiw	a5,a5,1
    800038cc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038ce:	00028517          	auipc	a0,0x28
    800038d2:	ee250513          	addi	a0,a0,-286 # 8002b7b0 <icache>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	3b4080e7          	jalr	948(ra) # 80000c8a <release>
}
    800038de:	8526                	mv	a0,s1
    800038e0:	60e2                	ld	ra,24(sp)
    800038e2:	6442                	ld	s0,16(sp)
    800038e4:	64a2                	ld	s1,8(sp)
    800038e6:	6105                	addi	sp,sp,32
    800038e8:	8082                	ret

00000000800038ea <ilock>:
{
    800038ea:	1101                	addi	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	e04a                	sd	s2,0(sp)
    800038f4:	1000                	addi	s0,sp,32
    800038f6:	84aa                	mv	s1,a0
  if(ip->ref < 1){
    800038f8:	451c                	lw	a5,8(a0)
    800038fa:	02f05063          	blez	a5,8000391a <ilock+0x30>
  acquiresleep(&ip->lock);
    800038fe:	01048513          	addi	a0,s1,16
    80003902:	00001097          	auipc	ra,0x1
    80003906:	cd0080e7          	jalr	-816(ra) # 800045d2 <acquiresleep>
  if(ip->valid == 0){
    8000390a:	40bc                	lw	a5,64(s1)
    8000390c:	cb95                	beqz	a5,80003940 <ilock+0x56>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6902                	ld	s2,0(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret
    printf("hello world\n");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	cf650513          	addi	a0,a0,-778 # 80008610 <syscalls+0x190>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	c58080e7          	jalr	-936(ra) # 8000057a <printf>
  if(ip == 0 || ip->ref < 1)
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	fcf049e3          	bgtz	a5,800038fe <ilock+0x14>
    panic("ilock");
    80003930:	00005517          	auipc	a0,0x5
    80003934:	cf050513          	addi	a0,a0,-784 # 80008620 <syscalls+0x1a0>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	bf8080e7          	jalr	-1032(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003940:	40dc                	lw	a5,4(s1)
    80003942:	0047d79b          	srliw	a5,a5,0x4
    80003946:	00028597          	auipc	a1,0x28
    8000394a:	e625a583          	lw	a1,-414(a1) # 8002b7a8 <sb+0x18>
    8000394e:	9dbd                	addw	a1,a1,a5
    80003950:	4088                	lw	a0,0(s1)
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	796080e7          	jalr	1942(ra) # 800030e8 <bread>
    8000395a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395c:	05850593          	addi	a1,a0,88
    80003960:	40dc                	lw	a5,4(s1)
    80003962:	8bbd                	andi	a5,a5,15
    80003964:	079a                	slli	a5,a5,0x6
    80003966:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003968:	00059783          	lh	a5,0(a1)
    8000396c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003970:	00259783          	lh	a5,2(a1)
    80003974:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003978:	00459783          	lh	a5,4(a1)
    8000397c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003980:	00659783          	lh	a5,6(a1)
    80003984:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003988:	459c                	lw	a5,8(a1)
    8000398a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000398c:	03400613          	li	a2,52
    80003990:	05b1                	addi	a1,a1,12
    80003992:	05048513          	addi	a0,s1,80
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	39c080e7          	jalr	924(ra) # 80000d32 <memmove>
    brelse(bp);
    8000399e:	854a                	mv	a0,s2
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	878080e7          	jalr	-1928(ra) # 80003218 <brelse>
    ip->valid = 1;
    800039a8:	4785                	li	a5,1
    800039aa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ac:	04449783          	lh	a5,68(s1)
    800039b0:	ffb9                	bnez	a5,8000390e <ilock+0x24>
      panic("ilock: no type");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	c7650513          	addi	a0,a0,-906 # 80008628 <syscalls+0x1a8>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b76080e7          	jalr	-1162(ra) # 80000530 <panic>

00000000800039c2 <iunlock>:
{
    800039c2:	1101                	addi	sp,sp,-32
    800039c4:	ec06                	sd	ra,24(sp)
    800039c6:	e822                	sd	s0,16(sp)
    800039c8:	e426                	sd	s1,8(sp)
    800039ca:	e04a                	sd	s2,0(sp)
    800039cc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ce:	c905                	beqz	a0,800039fe <iunlock+0x3c>
    800039d0:	84aa                	mv	s1,a0
    800039d2:	01050913          	addi	s2,a0,16
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	c94080e7          	jalr	-876(ra) # 8000466c <holdingsleep>
    800039e0:	cd19                	beqz	a0,800039fe <iunlock+0x3c>
    800039e2:	449c                	lw	a5,8(s1)
    800039e4:	00f05d63          	blez	a5,800039fe <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	c3e080e7          	jalr	-962(ra) # 80004628 <releasesleep>
}
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6902                	ld	s2,0(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret
    panic("iunlock");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	c3a50513          	addi	a0,a0,-966 # 80008638 <syscalls+0x1b8>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b2a080e7          	jalr	-1238(ra) # 80000530 <panic>

0000000080003a0e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a0e:	7179                	addi	sp,sp,-48
    80003a10:	f406                	sd	ra,40(sp)
    80003a12:	f022                	sd	s0,32(sp)
    80003a14:	ec26                	sd	s1,24(sp)
    80003a16:	e84a                	sd	s2,16(sp)
    80003a18:	e44e                	sd	s3,8(sp)
    80003a1a:	e052                	sd	s4,0(sp)
    80003a1c:	1800                	addi	s0,sp,48
    80003a1e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a20:	05050493          	addi	s1,a0,80
    80003a24:	08050913          	addi	s2,a0,128
    80003a28:	a021                	j	80003a30 <itrunc+0x22>
    80003a2a:	0491                	addi	s1,s1,4
    80003a2c:	01248d63          	beq	s1,s2,80003a46 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a30:	408c                	lw	a1,0(s1)
    80003a32:	dde5                	beqz	a1,80003a2a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a34:	0009a503          	lw	a0,0(s3)
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	8f6080e7          	jalr	-1802(ra) # 8000332e <bfree>
      ip->addrs[i] = 0;
    80003a40:	0004a023          	sw	zero,0(s1)
    80003a44:	b7dd                	j	80003a2a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a46:	0809a583          	lw	a1,128(s3)
    80003a4a:	e185                	bnez	a1,80003a6a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a4c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a50:	854e                	mv	a0,s3
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	dce080e7          	jalr	-562(ra) # 80003820 <iupdate>
}
    80003a5a:	70a2                	ld	ra,40(sp)
    80003a5c:	7402                	ld	s0,32(sp)
    80003a5e:	64e2                	ld	s1,24(sp)
    80003a60:	6942                	ld	s2,16(sp)
    80003a62:	69a2                	ld	s3,8(sp)
    80003a64:	6a02                	ld	s4,0(sp)
    80003a66:	6145                	addi	sp,sp,48
    80003a68:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a6a:	0009a503          	lw	a0,0(s3)
    80003a6e:	fffff097          	auipc	ra,0xfffff
    80003a72:	67a080e7          	jalr	1658(ra) # 800030e8 <bread>
    80003a76:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a78:	05850493          	addi	s1,a0,88
    80003a7c:	45850913          	addi	s2,a0,1112
    80003a80:	a811                	j	80003a94 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a82:	0009a503          	lw	a0,0(s3)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	8a8080e7          	jalr	-1880(ra) # 8000332e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a8e:	0491                	addi	s1,s1,4
    80003a90:	01248563          	beq	s1,s2,80003a9a <itrunc+0x8c>
      if(a[j])
    80003a94:	408c                	lw	a1,0(s1)
    80003a96:	dde5                	beqz	a1,80003a8e <itrunc+0x80>
    80003a98:	b7ed                	j	80003a82 <itrunc+0x74>
    brelse(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	77c080e7          	jalr	1916(ra) # 80003218 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa4:	0809a583          	lw	a1,128(s3)
    80003aa8:	0009a503          	lw	a0,0(s3)
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	882080e7          	jalr	-1918(ra) # 8000332e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab4:	0809a023          	sw	zero,128(s3)
    80003ab8:	bf51                	j	80003a4c <itrunc+0x3e>

0000000080003aba <iput>:
{
    80003aba:	1101                	addi	sp,sp,-32
    80003abc:	ec06                	sd	ra,24(sp)
    80003abe:	e822                	sd	s0,16(sp)
    80003ac0:	e426                	sd	s1,8(sp)
    80003ac2:	e04a                	sd	s2,0(sp)
    80003ac4:	1000                	addi	s0,sp,32
    80003ac6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ac8:	00028517          	auipc	a0,0x28
    80003acc:	ce850513          	addi	a0,a0,-792 # 8002b7b0 <icache>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	106080e7          	jalr	262(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad8:	4498                	lw	a4,8(s1)
    80003ada:	4785                	li	a5,1
    80003adc:	02f70363          	beq	a4,a5,80003b02 <iput+0x48>
  ip->ref--;
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	37fd                	addiw	a5,a5,-1
    80003ae4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ae6:	00028517          	auipc	a0,0x28
    80003aea:	cca50513          	addi	a0,a0,-822 # 8002b7b0 <icache>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	19c080e7          	jalr	412(ra) # 80000c8a <release>
}
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	64a2                	ld	s1,8(sp)
    80003afc:	6902                	ld	s2,0(sp)
    80003afe:	6105                	addi	sp,sp,32
    80003b00:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b02:	40bc                	lw	a5,64(s1)
    80003b04:	dff1                	beqz	a5,80003ae0 <iput+0x26>
    80003b06:	04a49783          	lh	a5,74(s1)
    80003b0a:	fbf9                	bnez	a5,80003ae0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b0c:	01048913          	addi	s2,s1,16
    80003b10:	854a                	mv	a0,s2
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	ac0080e7          	jalr	-1344(ra) # 800045d2 <acquiresleep>
    release(&icache.lock);
    80003b1a:	00028517          	auipc	a0,0x28
    80003b1e:	c9650513          	addi	a0,a0,-874 # 8002b7b0 <icache>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	168080e7          	jalr	360(ra) # 80000c8a <release>
    itrunc(ip);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	ee2080e7          	jalr	-286(ra) # 80003a0e <itrunc>
    ip->type = 0;
    80003b34:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	ce6080e7          	jalr	-794(ra) # 80003820 <iupdate>
    ip->valid = 0;
    80003b42:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b46:	854a                	mv	a0,s2
    80003b48:	00001097          	auipc	ra,0x1
    80003b4c:	ae0080e7          	jalr	-1312(ra) # 80004628 <releasesleep>
    acquire(&icache.lock);
    80003b50:	00028517          	auipc	a0,0x28
    80003b54:	c6050513          	addi	a0,a0,-928 # 8002b7b0 <icache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	07e080e7          	jalr	126(ra) # 80000bd6 <acquire>
    80003b60:	b741                	j	80003ae0 <iput+0x26>

0000000080003b62 <iunlockput>:
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	e54080e7          	jalr	-428(ra) # 800039c2 <iunlock>
  iput(ip);
    80003b76:	8526                	mv	a0,s1
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	f42080e7          	jalr	-190(ra) # 80003aba <iput>
}
    80003b80:	60e2                	ld	ra,24(sp)
    80003b82:	6442                	ld	s0,16(sp)
    80003b84:	64a2                	ld	s1,8(sp)
    80003b86:	6105                	addi	sp,sp,32
    80003b88:	8082                	ret

0000000080003b8a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b8a:	1141                	addi	sp,sp,-16
    80003b8c:	e422                	sd	s0,8(sp)
    80003b8e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b90:	411c                	lw	a5,0(a0)
    80003b92:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b94:	415c                	lw	a5,4(a0)
    80003b96:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b98:	04451783          	lh	a5,68(a0)
    80003b9c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ba0:	04a51783          	lh	a5,74(a0)
    80003ba4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ba8:	04c56783          	lwu	a5,76(a0)
    80003bac:	e99c                	sd	a5,16(a1)
}
    80003bae:	6422                	ld	s0,8(sp)
    80003bb0:	0141                	addi	sp,sp,16
    80003bb2:	8082                	ret

0000000080003bb4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb4:	457c                	lw	a5,76(a0)
    80003bb6:	0ed7e963          	bltu	a5,a3,80003ca8 <readi+0xf4>
{
    80003bba:	7159                	addi	sp,sp,-112
    80003bbc:	f486                	sd	ra,104(sp)
    80003bbe:	f0a2                	sd	s0,96(sp)
    80003bc0:	eca6                	sd	s1,88(sp)
    80003bc2:	e8ca                	sd	s2,80(sp)
    80003bc4:	e4ce                	sd	s3,72(sp)
    80003bc6:	e0d2                	sd	s4,64(sp)
    80003bc8:	fc56                	sd	s5,56(sp)
    80003bca:	f85a                	sd	s6,48(sp)
    80003bcc:	f45e                	sd	s7,40(sp)
    80003bce:	f062                	sd	s8,32(sp)
    80003bd0:	ec66                	sd	s9,24(sp)
    80003bd2:	e86a                	sd	s10,16(sp)
    80003bd4:	e46e                	sd	s11,8(sp)
    80003bd6:	1880                	addi	s0,sp,112
    80003bd8:	8baa                	mv	s7,a0
    80003bda:	8c2e                	mv	s8,a1
    80003bdc:	8ab2                	mv	s5,a2
    80003bde:	84b6                	mv	s1,a3
    80003be0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003be2:	9f35                	addw	a4,a4,a3
    return 0;
    80003be4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003be6:	0ad76063          	bltu	a4,a3,80003c86 <readi+0xd2>
  if(off + n > ip->size)
    80003bea:	00e7f463          	bgeu	a5,a4,80003bf2 <readi+0x3e>
    n = ip->size - off;
    80003bee:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf2:	0a0b0963          	beqz	s6,80003ca4 <readi+0xf0>
    80003bf6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bfc:	5cfd                	li	s9,-1
    80003bfe:	a82d                	j	80003c38 <readi+0x84>
    80003c00:	020a1d93          	slli	s11,s4,0x20
    80003c04:	020ddd93          	srli	s11,s11,0x20
    80003c08:	05890613          	addi	a2,s2,88
    80003c0c:	86ee                	mv	a3,s11
    80003c0e:	963a                	add	a2,a2,a4
    80003c10:	85d6                	mv	a1,s5
    80003c12:	8562                	mv	a0,s8
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	998080e7          	jalr	-1640(ra) # 800025ac <either_copyout>
    80003c1c:	05950d63          	beq	a0,s9,80003c76 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c20:	854a                	mv	a0,s2
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	5f6080e7          	jalr	1526(ra) # 80003218 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2a:	013a09bb          	addw	s3,s4,s3
    80003c2e:	009a04bb          	addw	s1,s4,s1
    80003c32:	9aee                	add	s5,s5,s11
    80003c34:	0569f763          	bgeu	s3,s6,80003c82 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c38:	000ba903          	lw	s2,0(s7)
    80003c3c:	00a4d59b          	srliw	a1,s1,0xa
    80003c40:	855e                	mv	a0,s7
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	89a080e7          	jalr	-1894(ra) # 800034dc <bmap>
    80003c4a:	0005059b          	sext.w	a1,a0
    80003c4e:	854a                	mv	a0,s2
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	498080e7          	jalr	1176(ra) # 800030e8 <bread>
    80003c58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5a:	3ff4f713          	andi	a4,s1,1023
    80003c5e:	40ed07bb          	subw	a5,s10,a4
    80003c62:	413b06bb          	subw	a3,s6,s3
    80003c66:	8a3e                	mv	s4,a5
    80003c68:	2781                	sext.w	a5,a5
    80003c6a:	0006861b          	sext.w	a2,a3
    80003c6e:	f8f679e3          	bgeu	a2,a5,80003c00 <readi+0x4c>
    80003c72:	8a36                	mv	s4,a3
    80003c74:	b771                	j	80003c00 <readi+0x4c>
      brelse(bp);
    80003c76:	854a                	mv	a0,s2
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	5a0080e7          	jalr	1440(ra) # 80003218 <brelse>
      tot = -1;
    80003c80:	59fd                	li	s3,-1
  }
  return tot;
    80003c82:	0009851b          	sext.w	a0,s3
}
    80003c86:	70a6                	ld	ra,104(sp)
    80003c88:	7406                	ld	s0,96(sp)
    80003c8a:	64e6                	ld	s1,88(sp)
    80003c8c:	6946                	ld	s2,80(sp)
    80003c8e:	69a6                	ld	s3,72(sp)
    80003c90:	6a06                	ld	s4,64(sp)
    80003c92:	7ae2                	ld	s5,56(sp)
    80003c94:	7b42                	ld	s6,48(sp)
    80003c96:	7ba2                	ld	s7,40(sp)
    80003c98:	7c02                	ld	s8,32(sp)
    80003c9a:	6ce2                	ld	s9,24(sp)
    80003c9c:	6d42                	ld	s10,16(sp)
    80003c9e:	6da2                	ld	s11,8(sp)
    80003ca0:	6165                	addi	sp,sp,112
    80003ca2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca4:	89da                	mv	s3,s6
    80003ca6:	bff1                	j	80003c82 <readi+0xce>
    return 0;
    80003ca8:	4501                	li	a0,0
}
    80003caa:	8082                	ret

0000000080003cac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cac:	457c                	lw	a5,76(a0)
    80003cae:	10d7e863          	bltu	a5,a3,80003dbe <writei+0x112>
{
    80003cb2:	7159                	addi	sp,sp,-112
    80003cb4:	f486                	sd	ra,104(sp)
    80003cb6:	f0a2                	sd	s0,96(sp)
    80003cb8:	eca6                	sd	s1,88(sp)
    80003cba:	e8ca                	sd	s2,80(sp)
    80003cbc:	e4ce                	sd	s3,72(sp)
    80003cbe:	e0d2                	sd	s4,64(sp)
    80003cc0:	fc56                	sd	s5,56(sp)
    80003cc2:	f85a                	sd	s6,48(sp)
    80003cc4:	f45e                	sd	s7,40(sp)
    80003cc6:	f062                	sd	s8,32(sp)
    80003cc8:	ec66                	sd	s9,24(sp)
    80003cca:	e86a                	sd	s10,16(sp)
    80003ccc:	e46e                	sd	s11,8(sp)
    80003cce:	1880                	addi	s0,sp,112
    80003cd0:	8b2a                	mv	s6,a0
    80003cd2:	8c2e                	mv	s8,a1
    80003cd4:	8ab2                	mv	s5,a2
    80003cd6:	8936                	mv	s2,a3
    80003cd8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cda:	00e687bb          	addw	a5,a3,a4
    80003cde:	0ed7e263          	bltu	a5,a3,80003dc2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ce2:	00043737          	lui	a4,0x43
    80003ce6:	0ef76063          	bltu	a4,a5,80003dc6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cea:	0c0b8863          	beqz	s7,80003dba <writei+0x10e>
    80003cee:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cf4:	5cfd                	li	s9,-1
    80003cf6:	a091                	j	80003d3a <writei+0x8e>
    80003cf8:	02099d93          	slli	s11,s3,0x20
    80003cfc:	020ddd93          	srli	s11,s11,0x20
    80003d00:	05848513          	addi	a0,s1,88
    80003d04:	86ee                	mv	a3,s11
    80003d06:	8656                	mv	a2,s5
    80003d08:	85e2                	mv	a1,s8
    80003d0a:	953a                	add	a0,a0,a4
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	8f6080e7          	jalr	-1802(ra) # 80002602 <either_copyin>
    80003d14:	07950263          	beq	a0,s9,80003d78 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d18:	8526                	mv	a0,s1
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	790080e7          	jalr	1936(ra) # 800044aa <log_write>
    brelse(bp);
    80003d22:	8526                	mv	a0,s1
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	4f4080e7          	jalr	1268(ra) # 80003218 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2c:	01498a3b          	addw	s4,s3,s4
    80003d30:	0129893b          	addw	s2,s3,s2
    80003d34:	9aee                	add	s5,s5,s11
    80003d36:	057a7663          	bgeu	s4,s7,80003d82 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d3a:	000b2483          	lw	s1,0(s6)
    80003d3e:	00a9559b          	srliw	a1,s2,0xa
    80003d42:	855a                	mv	a0,s6
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	798080e7          	jalr	1944(ra) # 800034dc <bmap>
    80003d4c:	0005059b          	sext.w	a1,a0
    80003d50:	8526                	mv	a0,s1
    80003d52:	fffff097          	auipc	ra,0xfffff
    80003d56:	396080e7          	jalr	918(ra) # 800030e8 <bread>
    80003d5a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5c:	3ff97713          	andi	a4,s2,1023
    80003d60:	40ed07bb          	subw	a5,s10,a4
    80003d64:	414b86bb          	subw	a3,s7,s4
    80003d68:	89be                	mv	s3,a5
    80003d6a:	2781                	sext.w	a5,a5
    80003d6c:	0006861b          	sext.w	a2,a3
    80003d70:	f8f674e3          	bgeu	a2,a5,80003cf8 <writei+0x4c>
    80003d74:	89b6                	mv	s3,a3
    80003d76:	b749                	j	80003cf8 <writei+0x4c>
      brelse(bp);
    80003d78:	8526                	mv	a0,s1
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	49e080e7          	jalr	1182(ra) # 80003218 <brelse>
  }

  if(off > ip->size)
    80003d82:	04cb2783          	lw	a5,76(s6)
    80003d86:	0127f463          	bgeu	a5,s2,80003d8e <writei+0xe2>
    ip->size = off;
    80003d8a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d8e:	855a                	mv	a0,s6
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	a90080e7          	jalr	-1392(ra) # 80003820 <iupdate>

  return tot;
    80003d98:	000a051b          	sext.w	a0,s4
}
    80003d9c:	70a6                	ld	ra,104(sp)
    80003d9e:	7406                	ld	s0,96(sp)
    80003da0:	64e6                	ld	s1,88(sp)
    80003da2:	6946                	ld	s2,80(sp)
    80003da4:	69a6                	ld	s3,72(sp)
    80003da6:	6a06                	ld	s4,64(sp)
    80003da8:	7ae2                	ld	s5,56(sp)
    80003daa:	7b42                	ld	s6,48(sp)
    80003dac:	7ba2                	ld	s7,40(sp)
    80003dae:	7c02                	ld	s8,32(sp)
    80003db0:	6ce2                	ld	s9,24(sp)
    80003db2:	6d42                	ld	s10,16(sp)
    80003db4:	6da2                	ld	s11,8(sp)
    80003db6:	6165                	addi	sp,sp,112
    80003db8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dba:	8a5e                	mv	s4,s7
    80003dbc:	bfc9                	j	80003d8e <writei+0xe2>
    return -1;
    80003dbe:	557d                	li	a0,-1
}
    80003dc0:	8082                	ret
    return -1;
    80003dc2:	557d                	li	a0,-1
    80003dc4:	bfe1                	j	80003d9c <writei+0xf0>
    return -1;
    80003dc6:	557d                	li	a0,-1
    80003dc8:	bfd1                	j	80003d9c <writei+0xf0>

0000000080003dca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dca:	1141                	addi	sp,sp,-16
    80003dcc:	e406                	sd	ra,8(sp)
    80003dce:	e022                	sd	s0,0(sp)
    80003dd0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dd2:	4639                	li	a2,14
    80003dd4:	ffffd097          	auipc	ra,0xffffd
    80003dd8:	fda080e7          	jalr	-38(ra) # 80000dae <strncmp>
}
    80003ddc:	60a2                	ld	ra,8(sp)
    80003dde:	6402                	ld	s0,0(sp)
    80003de0:	0141                	addi	sp,sp,16
    80003de2:	8082                	ret

0000000080003de4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003de4:	7139                	addi	sp,sp,-64
    80003de6:	fc06                	sd	ra,56(sp)
    80003de8:	f822                	sd	s0,48(sp)
    80003dea:	f426                	sd	s1,40(sp)
    80003dec:	f04a                	sd	s2,32(sp)
    80003dee:	ec4e                	sd	s3,24(sp)
    80003df0:	e852                	sd	s4,16(sp)
    80003df2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003df4:	04451703          	lh	a4,68(a0)
    80003df8:	4785                	li	a5,1
    80003dfa:	00f71a63          	bne	a4,a5,80003e0e <dirlookup+0x2a>
    80003dfe:	892a                	mv	s2,a0
    80003e00:	89ae                	mv	s3,a1
    80003e02:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e04:	457c                	lw	a5,76(a0)
    80003e06:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e08:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0a:	e79d                	bnez	a5,80003e38 <dirlookup+0x54>
    80003e0c:	a8a5                	j	80003e84 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e0e:	00005517          	auipc	a0,0x5
    80003e12:	83250513          	addi	a0,a0,-1998 # 80008640 <syscalls+0x1c0>
    80003e16:	ffffc097          	auipc	ra,0xffffc
    80003e1a:	71a080e7          	jalr	1818(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003e1e:	00005517          	auipc	a0,0x5
    80003e22:	83a50513          	addi	a0,a0,-1990 # 80008658 <syscalls+0x1d8>
    80003e26:	ffffc097          	auipc	ra,0xffffc
    80003e2a:	70a080e7          	jalr	1802(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2e:	24c1                	addiw	s1,s1,16
    80003e30:	04c92783          	lw	a5,76(s2)
    80003e34:	04f4f763          	bgeu	s1,a5,80003e82 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e38:	4741                	li	a4,16
    80003e3a:	86a6                	mv	a3,s1
    80003e3c:	fc040613          	addi	a2,s0,-64
    80003e40:	4581                	li	a1,0
    80003e42:	854a                	mv	a0,s2
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	d70080e7          	jalr	-656(ra) # 80003bb4 <readi>
    80003e4c:	47c1                	li	a5,16
    80003e4e:	fcf518e3          	bne	a0,a5,80003e1e <dirlookup+0x3a>
    if(de.inum == 0)
    80003e52:	fc045783          	lhu	a5,-64(s0)
    80003e56:	dfe1                	beqz	a5,80003e2e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e58:	fc240593          	addi	a1,s0,-62
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	f6c080e7          	jalr	-148(ra) # 80003dca <namecmp>
    80003e66:	f561                	bnez	a0,80003e2e <dirlookup+0x4a>
      if(poff)
    80003e68:	000a0463          	beqz	s4,80003e70 <dirlookup+0x8c>
        *poff = off;
    80003e6c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e70:	fc045583          	lhu	a1,-64(s0)
    80003e74:	00092503          	lw	a0,0(s2)
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	73e080e7          	jalr	1854(ra) # 800035b6 <iget>
    80003e80:	a011                	j	80003e84 <dirlookup+0xa0>
  return 0;
    80003e82:	4501                	li	a0,0
}
    80003e84:	70e2                	ld	ra,56(sp)
    80003e86:	7442                	ld	s0,48(sp)
    80003e88:	74a2                	ld	s1,40(sp)
    80003e8a:	7902                	ld	s2,32(sp)
    80003e8c:	69e2                	ld	s3,24(sp)
    80003e8e:	6a42                	ld	s4,16(sp)
    80003e90:	6121                	addi	sp,sp,64
    80003e92:	8082                	ret

0000000080003e94 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e94:	711d                	addi	sp,sp,-96
    80003e96:	ec86                	sd	ra,88(sp)
    80003e98:	e8a2                	sd	s0,80(sp)
    80003e9a:	e4a6                	sd	s1,72(sp)
    80003e9c:	e0ca                	sd	s2,64(sp)
    80003e9e:	fc4e                	sd	s3,56(sp)
    80003ea0:	f852                	sd	s4,48(sp)
    80003ea2:	f456                	sd	s5,40(sp)
    80003ea4:	f05a                	sd	s6,32(sp)
    80003ea6:	ec5e                	sd	s7,24(sp)
    80003ea8:	e862                	sd	s8,16(sp)
    80003eaa:	e466                	sd	s9,8(sp)
    80003eac:	1080                	addi	s0,sp,96
    80003eae:	84aa                	mv	s1,a0
    80003eb0:	8b2e                	mv	s6,a1
    80003eb2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eb4:	00054703          	lbu	a4,0(a0)
    80003eb8:	02f00793          	li	a5,47
    80003ebc:	02f70363          	beq	a4,a5,80003ee2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ec0:	ffffe097          	auipc	ra,0xffffe
    80003ec4:	bc6080e7          	jalr	-1082(ra) # 80001a86 <myproc>
    80003ec8:	15053503          	ld	a0,336(a0)
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	9e0080e7          	jalr	-1568(ra) # 800038ac <idup>
    80003ed4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ed6:	02f00913          	li	s2,47
  len = path - s;
    80003eda:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003edc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ede:	4c05                	li	s8,1
    80003ee0:	a865                	j	80003f98 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ee2:	4585                	li	a1,1
    80003ee4:	4505                	li	a0,1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	6d0080e7          	jalr	1744(ra) # 800035b6 <iget>
    80003eee:	89aa                	mv	s3,a0
    80003ef0:	b7dd                	j	80003ed6 <namex+0x42>
      iunlockput(ip);
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	c6e080e7          	jalr	-914(ra) # 80003b62 <iunlockput>
      return 0;
    80003efc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003efe:	854e                	mv	a0,s3
    80003f00:	60e6                	ld	ra,88(sp)
    80003f02:	6446                	ld	s0,80(sp)
    80003f04:	64a6                	ld	s1,72(sp)
    80003f06:	6906                	ld	s2,64(sp)
    80003f08:	79e2                	ld	s3,56(sp)
    80003f0a:	7a42                	ld	s4,48(sp)
    80003f0c:	7aa2                	ld	s5,40(sp)
    80003f0e:	7b02                	ld	s6,32(sp)
    80003f10:	6be2                	ld	s7,24(sp)
    80003f12:	6c42                	ld	s8,16(sp)
    80003f14:	6ca2                	ld	s9,8(sp)
    80003f16:	6125                	addi	sp,sp,96
    80003f18:	8082                	ret
      iunlock(ip);
    80003f1a:	854e                	mv	a0,s3
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	aa6080e7          	jalr	-1370(ra) # 800039c2 <iunlock>
      return ip;
    80003f24:	bfe9                	j	80003efe <namex+0x6a>
      iunlockput(ip);
    80003f26:	854e                	mv	a0,s3
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	c3a080e7          	jalr	-966(ra) # 80003b62 <iunlockput>
      return 0;
    80003f30:	89d2                	mv	s3,s4
    80003f32:	b7f1                	j	80003efe <namex+0x6a>
  len = path - s;
    80003f34:	40b48633          	sub	a2,s1,a1
    80003f38:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f3c:	094cd463          	bge	s9,s4,80003fc4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f40:	4639                	li	a2,14
    80003f42:	8556                	mv	a0,s5
    80003f44:	ffffd097          	auipc	ra,0xffffd
    80003f48:	dee080e7          	jalr	-530(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003f4c:	0004c783          	lbu	a5,0(s1)
    80003f50:	01279763          	bne	a5,s2,80003f5e <namex+0xca>
    path++;
    80003f54:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f56:	0004c783          	lbu	a5,0(s1)
    80003f5a:	ff278de3          	beq	a5,s2,80003f54 <namex+0xc0>
    ilock(ip);
    80003f5e:	854e                	mv	a0,s3
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	98a080e7          	jalr	-1654(ra) # 800038ea <ilock>
    if(ip->type != T_DIR){
    80003f68:	04499783          	lh	a5,68(s3)
    80003f6c:	f98793e3          	bne	a5,s8,80003ef2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f70:	000b0563          	beqz	s6,80003f7a <namex+0xe6>
    80003f74:	0004c783          	lbu	a5,0(s1)
    80003f78:	d3cd                	beqz	a5,80003f1a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f7a:	865e                	mv	a2,s7
    80003f7c:	85d6                	mv	a1,s5
    80003f7e:	854e                	mv	a0,s3
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	e64080e7          	jalr	-412(ra) # 80003de4 <dirlookup>
    80003f88:	8a2a                	mv	s4,a0
    80003f8a:	dd51                	beqz	a0,80003f26 <namex+0x92>
    iunlockput(ip);
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	bd4080e7          	jalr	-1068(ra) # 80003b62 <iunlockput>
    ip = next;
    80003f96:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	05279763          	bne	a5,s2,80003fea <namex+0x156>
    path++;
    80003fa0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	ff278de3          	beq	a5,s2,80003fa0 <namex+0x10c>
  if(*path == 0)
    80003faa:	c79d                	beqz	a5,80003fd8 <namex+0x144>
    path++;
    80003fac:	85a6                	mv	a1,s1
  len = path - s;
    80003fae:	8a5e                	mv	s4,s7
    80003fb0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fb2:	01278963          	beq	a5,s2,80003fc4 <namex+0x130>
    80003fb6:	dfbd                	beqz	a5,80003f34 <namex+0xa0>
    path++;
    80003fb8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	ff279ce3          	bne	a5,s2,80003fb6 <namex+0x122>
    80003fc2:	bf8d                	j	80003f34 <namex+0xa0>
    memmove(name, s, len);
    80003fc4:	2601                	sext.w	a2,a2
    80003fc6:	8556                	mv	a0,s5
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	d6a080e7          	jalr	-662(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003fd0:	9a56                	add	s4,s4,s5
    80003fd2:	000a0023          	sb	zero,0(s4)
    80003fd6:	bf9d                	j	80003f4c <namex+0xb8>
  if(nameiparent){
    80003fd8:	f20b03e3          	beqz	s6,80003efe <namex+0x6a>
    iput(ip);
    80003fdc:	854e                	mv	a0,s3
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	adc080e7          	jalr	-1316(ra) # 80003aba <iput>
    return 0;
    80003fe6:	4981                	li	s3,0
    80003fe8:	bf19                	j	80003efe <namex+0x6a>
  if(*path == 0)
    80003fea:	d7fd                	beqz	a5,80003fd8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	85a6                	mv	a1,s1
    80003ff2:	b7d1                	j	80003fb6 <namex+0x122>

0000000080003ff4 <dirlink>:
{
    80003ff4:	7139                	addi	sp,sp,-64
    80003ff6:	fc06                	sd	ra,56(sp)
    80003ff8:	f822                	sd	s0,48(sp)
    80003ffa:	f426                	sd	s1,40(sp)
    80003ffc:	f04a                	sd	s2,32(sp)
    80003ffe:	ec4e                	sd	s3,24(sp)
    80004000:	e852                	sd	s4,16(sp)
    80004002:	0080                	addi	s0,sp,64
    80004004:	892a                	mv	s2,a0
    80004006:	8a2e                	mv	s4,a1
    80004008:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000400a:	4601                	li	a2,0
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	dd8080e7          	jalr	-552(ra) # 80003de4 <dirlookup>
    80004014:	e93d                	bnez	a0,8000408a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004016:	04c92483          	lw	s1,76(s2)
    8000401a:	c49d                	beqz	s1,80004048 <dirlink+0x54>
    8000401c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401e:	4741                	li	a4,16
    80004020:	86a6                	mv	a3,s1
    80004022:	fc040613          	addi	a2,s0,-64
    80004026:	4581                	li	a1,0
    80004028:	854a                	mv	a0,s2
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	b8a080e7          	jalr	-1142(ra) # 80003bb4 <readi>
    80004032:	47c1                	li	a5,16
    80004034:	06f51163          	bne	a0,a5,80004096 <dirlink+0xa2>
    if(de.inum == 0)
    80004038:	fc045783          	lhu	a5,-64(s0)
    8000403c:	c791                	beqz	a5,80004048 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403e:	24c1                	addiw	s1,s1,16
    80004040:	04c92783          	lw	a5,76(s2)
    80004044:	fcf4ede3          	bltu	s1,a5,8000401e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004048:	4639                	li	a2,14
    8000404a:	85d2                	mv	a1,s4
    8000404c:	fc240513          	addi	a0,s0,-62
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	d9a080e7          	jalr	-614(ra) # 80000dea <strncpy>
  de.inum = inum;
    80004058:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000405c:	4741                	li	a4,16
    8000405e:	86a6                	mv	a3,s1
    80004060:	fc040613          	addi	a2,s0,-64
    80004064:	4581                	li	a1,0
    80004066:	854a                	mv	a0,s2
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	c44080e7          	jalr	-956(ra) # 80003cac <writei>
    80004070:	872a                	mv	a4,a0
    80004072:	47c1                	li	a5,16
  return 0;
    80004074:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004076:	02f71863          	bne	a4,a5,800040a6 <dirlink+0xb2>
}
    8000407a:	70e2                	ld	ra,56(sp)
    8000407c:	7442                	ld	s0,48(sp)
    8000407e:	74a2                	ld	s1,40(sp)
    80004080:	7902                	ld	s2,32(sp)
    80004082:	69e2                	ld	s3,24(sp)
    80004084:	6a42                	ld	s4,16(sp)
    80004086:	6121                	addi	sp,sp,64
    80004088:	8082                	ret
    iput(ip);
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	a30080e7          	jalr	-1488(ra) # 80003aba <iput>
    return -1;
    80004092:	557d                	li	a0,-1
    80004094:	b7dd                	j	8000407a <dirlink+0x86>
      panic("dirlink read");
    80004096:	00004517          	auipc	a0,0x4
    8000409a:	5d250513          	addi	a0,a0,1490 # 80008668 <syscalls+0x1e8>
    8000409e:	ffffc097          	auipc	ra,0xffffc
    800040a2:	492080e7          	jalr	1170(ra) # 80000530 <panic>
    panic("dirlink");
    800040a6:	00004517          	auipc	a0,0x4
    800040aa:	6ca50513          	addi	a0,a0,1738 # 80008770 <syscalls+0x2f0>
    800040ae:	ffffc097          	auipc	ra,0xffffc
    800040b2:	482080e7          	jalr	1154(ra) # 80000530 <panic>

00000000800040b6 <namei>:

struct inode*
namei(char *path)
{
    800040b6:	1101                	addi	sp,sp,-32
    800040b8:	ec06                	sd	ra,24(sp)
    800040ba:	e822                	sd	s0,16(sp)
    800040bc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040be:	fe040613          	addi	a2,s0,-32
    800040c2:	4581                	li	a1,0
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	dd0080e7          	jalr	-560(ra) # 80003e94 <namex>
}
    800040cc:	60e2                	ld	ra,24(sp)
    800040ce:	6442                	ld	s0,16(sp)
    800040d0:	6105                	addi	sp,sp,32
    800040d2:	8082                	ret

00000000800040d4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040d4:	1141                	addi	sp,sp,-16
    800040d6:	e406                	sd	ra,8(sp)
    800040d8:	e022                	sd	s0,0(sp)
    800040da:	0800                	addi	s0,sp,16
    800040dc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040de:	4585                	li	a1,1
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	db4080e7          	jalr	-588(ra) # 80003e94 <namex>
}
    800040e8:	60a2                	ld	ra,8(sp)
    800040ea:	6402                	ld	s0,0(sp)
    800040ec:	0141                	addi	sp,sp,16
    800040ee:	8082                	ret

00000000800040f0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040f0:	1101                	addi	sp,sp,-32
    800040f2:	ec06                	sd	ra,24(sp)
    800040f4:	e822                	sd	s0,16(sp)
    800040f6:	e426                	sd	s1,8(sp)
    800040f8:	e04a                	sd	s2,0(sp)
    800040fa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040fc:	00029917          	auipc	s2,0x29
    80004100:	15c90913          	addi	s2,s2,348 # 8002d258 <log>
    80004104:	01892583          	lw	a1,24(s2)
    80004108:	02892503          	lw	a0,40(s2)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	fdc080e7          	jalr	-36(ra) # 800030e8 <bread>
    80004114:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004116:	02c92683          	lw	a3,44(s2)
    8000411a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000411c:	02d05763          	blez	a3,8000414a <write_head+0x5a>
    80004120:	00029797          	auipc	a5,0x29
    80004124:	16878793          	addi	a5,a5,360 # 8002d288 <log+0x30>
    80004128:	05c50713          	addi	a4,a0,92
    8000412c:	36fd                	addiw	a3,a3,-1
    8000412e:	1682                	slli	a3,a3,0x20
    80004130:	9281                	srli	a3,a3,0x20
    80004132:	068a                	slli	a3,a3,0x2
    80004134:	00029617          	auipc	a2,0x29
    80004138:	15860613          	addi	a2,a2,344 # 8002d28c <log+0x34>
    8000413c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000413e:	4390                	lw	a2,0(a5)
    80004140:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	0791                	addi	a5,a5,4
    80004144:	0711                	addi	a4,a4,4
    80004146:	fed79ce3          	bne	a5,a3,8000413e <write_head+0x4e>
  }
  bwrite(buf);
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	08e080e7          	jalr	142(ra) # 800031da <bwrite>
  brelse(buf);
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	0c2080e7          	jalr	194(ra) # 80003218 <brelse>
}
    8000415e:	60e2                	ld	ra,24(sp)
    80004160:	6442                	ld	s0,16(sp)
    80004162:	64a2                	ld	s1,8(sp)
    80004164:	6902                	ld	s2,0(sp)
    80004166:	6105                	addi	sp,sp,32
    80004168:	8082                	ret

000000008000416a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	00029797          	auipc	a5,0x29
    8000416e:	11a7a783          	lw	a5,282(a5) # 8002d284 <log+0x2c>
    80004172:	0af05d63          	blez	a5,8000422c <install_trans+0xc2>
{
    80004176:	7139                	addi	sp,sp,-64
    80004178:	fc06                	sd	ra,56(sp)
    8000417a:	f822                	sd	s0,48(sp)
    8000417c:	f426                	sd	s1,40(sp)
    8000417e:	f04a                	sd	s2,32(sp)
    80004180:	ec4e                	sd	s3,24(sp)
    80004182:	e852                	sd	s4,16(sp)
    80004184:	e456                	sd	s5,8(sp)
    80004186:	e05a                	sd	s6,0(sp)
    80004188:	0080                	addi	s0,sp,64
    8000418a:	8b2a                	mv	s6,a0
    8000418c:	00029a97          	auipc	s5,0x29
    80004190:	0fca8a93          	addi	s5,s5,252 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004194:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004196:	00029997          	auipc	s3,0x29
    8000419a:	0c298993          	addi	s3,s3,194 # 8002d258 <log>
    8000419e:	a035                	j	800041ca <install_trans+0x60>
      bunpin(dbuf);
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	150080e7          	jalr	336(ra) # 800032f2 <bunpin>
    brelse(lbuf);
    800041aa:	854a                	mv	a0,s2
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	06c080e7          	jalr	108(ra) # 80003218 <brelse>
    brelse(dbuf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	062080e7          	jalr	98(ra) # 80003218 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	2a05                	addiw	s4,s4,1
    800041c0:	0a91                	addi	s5,s5,4
    800041c2:	02c9a783          	lw	a5,44(s3)
    800041c6:	04fa5963          	bge	s4,a5,80004218 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ca:	0189a583          	lw	a1,24(s3)
    800041ce:	014585bb          	addw	a1,a1,s4
    800041d2:	2585                	addiw	a1,a1,1
    800041d4:	0289a503          	lw	a0,40(s3)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	f10080e7          	jalr	-240(ra) # 800030e8 <bread>
    800041e0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041e2:	000aa583          	lw	a1,0(s5)
    800041e6:	0289a503          	lw	a0,40(s3)
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	efe080e7          	jalr	-258(ra) # 800030e8 <bread>
    800041f2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041f4:	40000613          	li	a2,1024
    800041f8:	05890593          	addi	a1,s2,88
    800041fc:	05850513          	addi	a0,a0,88
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	b32080e7          	jalr	-1230(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	fd0080e7          	jalr	-48(ra) # 800031da <bwrite>
    if(recovering == 0)
    80004212:	f80b1ce3          	bnez	s6,800041aa <install_trans+0x40>
    80004216:	b769                	j	800041a0 <install_trans+0x36>
}
    80004218:	70e2                	ld	ra,56(sp)
    8000421a:	7442                	ld	s0,48(sp)
    8000421c:	74a2                	ld	s1,40(sp)
    8000421e:	7902                	ld	s2,32(sp)
    80004220:	69e2                	ld	s3,24(sp)
    80004222:	6a42                	ld	s4,16(sp)
    80004224:	6aa2                	ld	s5,8(sp)
    80004226:	6b02                	ld	s6,0(sp)
    80004228:	6121                	addi	sp,sp,64
    8000422a:	8082                	ret
    8000422c:	8082                	ret

000000008000422e <initlog>:
{
    8000422e:	7179                	addi	sp,sp,-48
    80004230:	f406                	sd	ra,40(sp)
    80004232:	f022                	sd	s0,32(sp)
    80004234:	ec26                	sd	s1,24(sp)
    80004236:	e84a                	sd	s2,16(sp)
    80004238:	e44e                	sd	s3,8(sp)
    8000423a:	1800                	addi	s0,sp,48
    8000423c:	892a                	mv	s2,a0
    8000423e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004240:	00029497          	auipc	s1,0x29
    80004244:	01848493          	addi	s1,s1,24 # 8002d258 <log>
    80004248:	00004597          	auipc	a1,0x4
    8000424c:	43058593          	addi	a1,a1,1072 # 80008678 <syscalls+0x1f8>
    80004250:	8526                	mv	a0,s1
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	8f4080e7          	jalr	-1804(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000425a:	0149a583          	lw	a1,20(s3)
    8000425e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004260:	0109a783          	lw	a5,16(s3)
    80004264:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004266:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000426a:	854a                	mv	a0,s2
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	e7c080e7          	jalr	-388(ra) # 800030e8 <bread>
  log.lh.n = lh->n;
    80004274:	4d3c                	lw	a5,88(a0)
    80004276:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004278:	02f05563          	blez	a5,800042a2 <initlog+0x74>
    8000427c:	05c50713          	addi	a4,a0,92
    80004280:	00029697          	auipc	a3,0x29
    80004284:	00868693          	addi	a3,a3,8 # 8002d288 <log+0x30>
    80004288:	37fd                	addiw	a5,a5,-1
    8000428a:	1782                	slli	a5,a5,0x20
    8000428c:	9381                	srli	a5,a5,0x20
    8000428e:	078a                	slli	a5,a5,0x2
    80004290:	06050613          	addi	a2,a0,96
    80004294:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004296:	4310                	lw	a2,0(a4)
    80004298:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000429a:	0711                	addi	a4,a4,4
    8000429c:	0691                	addi	a3,a3,4
    8000429e:	fef71ce3          	bne	a4,a5,80004296 <initlog+0x68>
  brelse(buf);
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	f76080e7          	jalr	-138(ra) # 80003218 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042aa:	4505                	li	a0,1
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	ebe080e7          	jalr	-322(ra) # 8000416a <install_trans>
  log.lh.n = 0;
    800042b4:	00029797          	auipc	a5,0x29
    800042b8:	fc07a823          	sw	zero,-48(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	e34080e7          	jalr	-460(ra) # 800040f0 <write_head>
}
    800042c4:	70a2                	ld	ra,40(sp)
    800042c6:	7402                	ld	s0,32(sp)
    800042c8:	64e2                	ld	s1,24(sp)
    800042ca:	6942                	ld	s2,16(sp)
    800042cc:	69a2                	ld	s3,8(sp)
    800042ce:	6145                	addi	sp,sp,48
    800042d0:	8082                	ret

00000000800042d2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042de:	00029517          	auipc	a0,0x29
    800042e2:	f7a50513          	addi	a0,a0,-134 # 8002d258 <log>
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	8f0080e7          	jalr	-1808(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800042ee:	00029497          	auipc	s1,0x29
    800042f2:	f6a48493          	addi	s1,s1,-150 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f6:	4979                	li	s2,30
    800042f8:	a039                	j	80004306 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042fa:	85a6                	mv	a1,s1
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffe097          	auipc	ra,0xffffe
    80004302:	04c080e7          	jalr	76(ra) # 8000234a <sleep>
    if(log.committing){
    80004306:	50dc                	lw	a5,36(s1)
    80004308:	fbed                	bnez	a5,800042fa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000430a:	509c                	lw	a5,32(s1)
    8000430c:	0017871b          	addiw	a4,a5,1
    80004310:	0007069b          	sext.w	a3,a4
    80004314:	0027179b          	slliw	a5,a4,0x2
    80004318:	9fb9                	addw	a5,a5,a4
    8000431a:	0017979b          	slliw	a5,a5,0x1
    8000431e:	54d8                	lw	a4,44(s1)
    80004320:	9fb9                	addw	a5,a5,a4
    80004322:	00f95963          	bge	s2,a5,80004334 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004326:	85a6                	mv	a1,s1
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffe097          	auipc	ra,0xffffe
    8000432e:	020080e7          	jalr	32(ra) # 8000234a <sleep>
    80004332:	bfd1                	j	80004306 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004334:	00029517          	auipc	a0,0x29
    80004338:	f2450513          	addi	a0,a0,-220 # 8002d258 <log>
    8000433c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	94c080e7          	jalr	-1716(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004346:	60e2                	ld	ra,24(sp)
    80004348:	6442                	ld	s0,16(sp)
    8000434a:	64a2                	ld	s1,8(sp)
    8000434c:	6902                	ld	s2,0(sp)
    8000434e:	6105                	addi	sp,sp,32
    80004350:	8082                	ret

0000000080004352 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004352:	7139                	addi	sp,sp,-64
    80004354:	fc06                	sd	ra,56(sp)
    80004356:	f822                	sd	s0,48(sp)
    80004358:	f426                	sd	s1,40(sp)
    8000435a:	f04a                	sd	s2,32(sp)
    8000435c:	ec4e                	sd	s3,24(sp)
    8000435e:	e852                	sd	s4,16(sp)
    80004360:	e456                	sd	s5,8(sp)
    80004362:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004364:	00029497          	auipc	s1,0x29
    80004368:	ef448493          	addi	s1,s1,-268 # 8002d258 <log>
    8000436c:	8526                	mv	a0,s1
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	868080e7          	jalr	-1944(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004376:	509c                	lw	a5,32(s1)
    80004378:	37fd                	addiw	a5,a5,-1
    8000437a:	0007891b          	sext.w	s2,a5
    8000437e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004380:	50dc                	lw	a5,36(s1)
    80004382:	efb9                	bnez	a5,800043e0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){//如果现在没有文件系统的系统调用了
    80004384:	06091663          	bnez	s2,800043f0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004388:	00029497          	auipc	s1,0x29
    8000438c:	ed048493          	addi	s1,s1,-304 # 8002d258 <log>
    80004390:	4785                	li	a5,1
    80004392:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004394:	8526                	mv	a0,s1
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000439e:	54dc                	lw	a5,44(s1)
    800043a0:	06f04763          	bgtz	a5,8000440e <end_op+0xbc>
    acquire(&log.lock);
    800043a4:	00029497          	auipc	s1,0x29
    800043a8:	eb448493          	addi	s1,s1,-332 # 8002d258 <log>
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	828080e7          	jalr	-2008(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800043b6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043ba:	8526                	mv	a0,s1
    800043bc:	ffffe097          	auipc	ra,0xffffe
    800043c0:	114080e7          	jalr	276(ra) # 800024d0 <wakeup>
    release(&log.lock);
    800043c4:	8526                	mv	a0,s1
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	8c4080e7          	jalr	-1852(ra) # 80000c8a <release>
}
    800043ce:	70e2                	ld	ra,56(sp)
    800043d0:	7442                	ld	s0,48(sp)
    800043d2:	74a2                	ld	s1,40(sp)
    800043d4:	7902                	ld	s2,32(sp)
    800043d6:	69e2                	ld	s3,24(sp)
    800043d8:	6a42                	ld	s4,16(sp)
    800043da:	6aa2                	ld	s5,8(sp)
    800043dc:	6121                	addi	sp,sp,64
    800043de:	8082                	ret
    panic("log.committing");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	2a050513          	addi	a0,a0,672 # 80008680 <syscalls+0x200>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	148080e7          	jalr	328(ra) # 80000530 <panic>
    wakeup(&log);
    800043f0:	00029497          	auipc	s1,0x29
    800043f4:	e6848493          	addi	s1,s1,-408 # 8002d258 <log>
    800043f8:	8526                	mv	a0,s1
    800043fa:	ffffe097          	auipc	ra,0xffffe
    800043fe:	0d6080e7          	jalr	214(ra) # 800024d0 <wakeup>
  release(&log.lock);
    80004402:	8526                	mv	a0,s1
    80004404:	ffffd097          	auipc	ra,0xffffd
    80004408:	886080e7          	jalr	-1914(ra) # 80000c8a <release>
  if(do_commit){
    8000440c:	b7c9                	j	800043ce <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440e:	00029a97          	auipc	s5,0x29
    80004412:	e7aa8a93          	addi	s5,s5,-390 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004416:	00029a17          	auipc	s4,0x29
    8000441a:	e42a0a13          	addi	s4,s4,-446 # 8002d258 <log>
    8000441e:	018a2583          	lw	a1,24(s4)
    80004422:	012585bb          	addw	a1,a1,s2
    80004426:	2585                	addiw	a1,a1,1
    80004428:	028a2503          	lw	a0,40(s4)
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	cbc080e7          	jalr	-836(ra) # 800030e8 <bread>
    80004434:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004436:	000aa583          	lw	a1,0(s5)
    8000443a:	028a2503          	lw	a0,40(s4)
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	caa080e7          	jalr	-854(ra) # 800030e8 <bread>
    80004446:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004448:	40000613          	li	a2,1024
    8000444c:	05850593          	addi	a1,a0,88
    80004450:	05848513          	addi	a0,s1,88
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	8de080e7          	jalr	-1826(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	d7c080e7          	jalr	-644(ra) # 800031da <bwrite>
    brelse(from);
    80004466:	854e                	mv	a0,s3
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	db0080e7          	jalr	-592(ra) # 80003218 <brelse>
    brelse(to);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	da6080e7          	jalr	-602(ra) # 80003218 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447a:	2905                	addiw	s2,s2,1
    8000447c:	0a91                	addi	s5,s5,4
    8000447e:	02ca2783          	lw	a5,44(s4)
    80004482:	f8f94ee3          	blt	s2,a5,8000441e <end_op+0xcc>
    write_log();     // 先把内存中保存的要更改的block存入log block中
    write_head();    // 把内存中的log header更新到磁盘上面去
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	c6a080e7          	jalr	-918(ra) # 800040f0 <write_head>
    install_trans(0); // 开始把log里面的给写入回原位置
    8000448e:	4501                	li	a0,0
    80004490:	00000097          	auipc	ra,0x0
    80004494:	cda080e7          	jalr	-806(ra) # 8000416a <install_trans>
    log.lh.n = 0;     //代表这个事务结束
    80004498:	00029797          	auipc	a5,0x29
    8000449c:	de07a623          	sw	zero,-532(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	c50080e7          	jalr	-944(ra) # 800040f0 <write_head>
    800044a8:	bdf5                	j	800043a4 <end_op+0x52>

00000000800044aa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044aa:	1101                	addi	sp,sp,-32
    800044ac:	ec06                	sd	ra,24(sp)
    800044ae:	e822                	sd	s0,16(sp)
    800044b0:	e426                	sd	s1,8(sp)
    800044b2:	e04a                	sd	s2,0(sp)
    800044b4:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044b6:	00029717          	auipc	a4,0x29
    800044ba:	dce72703          	lw	a4,-562(a4) # 8002d284 <log+0x2c>
    800044be:	47f5                	li	a5,29
    800044c0:	08e7c063          	blt	a5,a4,80004540 <log_write+0x96>
    800044c4:	84aa                	mv	s1,a0
    800044c6:	00029797          	auipc	a5,0x29
    800044ca:	dae7a783          	lw	a5,-594(a5) # 8002d274 <log+0x1c>
    800044ce:	37fd                	addiw	a5,a5,-1
    800044d0:	06f75863          	bge	a4,a5,80004540 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044d4:	00029797          	auipc	a5,0x29
    800044d8:	da47a783          	lw	a5,-604(a5) # 8002d278 <log+0x20>
    800044dc:	06f05a63          	blez	a5,80004550 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044e0:	00029917          	auipc	s2,0x29
    800044e4:	d7890913          	addi	s2,s2,-648 # 8002d258 <log>
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6ec080e7          	jalr	1772(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044f2:	02c92603          	lw	a2,44(s2)
    800044f6:	06c05563          	blez	a2,80004560 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044fa:	44cc                	lw	a1,12(s1)
    800044fc:	00029717          	auipc	a4,0x29
    80004500:	d8c70713          	addi	a4,a4,-628 # 8002d288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004504:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004506:	4314                	lw	a3,0(a4)
    80004508:	04b68d63          	beq	a3,a1,80004562 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000450c:	2785                	addiw	a5,a5,1
    8000450e:	0711                	addi	a4,a4,4
    80004510:	fec79be3          	bne	a5,a2,80004506 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;//把要更改的block先保存在内存中
    80004514:	0621                	addi	a2,a2,8
    80004516:	060a                	slli	a2,a2,0x2
    80004518:	00029797          	auipc	a5,0x29
    8000451c:	d4078793          	addi	a5,a5,-704 # 8002d258 <log>
    80004520:	963e                	add	a2,a2,a5
    80004522:	44dc                	lw	a5,12(s1)
    80004524:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004526:	8526                	mv	a0,s1
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	d8e080e7          	jalr	-626(ra) # 800032b6 <bpin>
    log.lh.n++;
    80004530:	00029717          	auipc	a4,0x29
    80004534:	d2870713          	addi	a4,a4,-728 # 8002d258 <log>
    80004538:	575c                	lw	a5,44(a4)
    8000453a:	2785                	addiw	a5,a5,1
    8000453c:	d75c                	sw	a5,44(a4)
    8000453e:	a83d                	j	8000457c <log_write+0xd2>
    panic("too big a transaction");
    80004540:	00004517          	auipc	a0,0x4
    80004544:	15050513          	addi	a0,a0,336 # 80008690 <syscalls+0x210>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	fe8080e7          	jalr	-24(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    80004550:	00004517          	auipc	a0,0x4
    80004554:	15850513          	addi	a0,a0,344 # 800086a8 <syscalls+0x228>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	fd8080e7          	jalr	-40(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004560:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;//把要更改的block先保存在内存中
    80004562:	00878713          	addi	a4,a5,8
    80004566:	00271693          	slli	a3,a4,0x2
    8000456a:	00029717          	auipc	a4,0x29
    8000456e:	cee70713          	addi	a4,a4,-786 # 8002d258 <log>
    80004572:	9736                	add	a4,a4,a3
    80004574:	44d4                	lw	a3,12(s1)
    80004576:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004578:	faf607e3          	beq	a2,a5,80004526 <log_write+0x7c>
  }
  release(&log.lock);
    8000457c:	00029517          	auipc	a0,0x29
    80004580:	cdc50513          	addi	a0,a0,-804 # 8002d258 <log>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	706080e7          	jalr	1798(ra) # 80000c8a <release>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004598:	1101                	addi	sp,sp,-32
    8000459a:	ec06                	sd	ra,24(sp)
    8000459c:	e822                	sd	s0,16(sp)
    8000459e:	e426                	sd	s1,8(sp)
    800045a0:	e04a                	sd	s2,0(sp)
    800045a2:	1000                	addi	s0,sp,32
    800045a4:	84aa                	mv	s1,a0
    800045a6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045a8:	00004597          	auipc	a1,0x4
    800045ac:	12058593          	addi	a1,a1,288 # 800086c8 <syscalls+0x248>
    800045b0:	0521                	addi	a0,a0,8
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	594080e7          	jalr	1428(ra) # 80000b46 <initlock>
  lk->name = name;
    800045ba:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045c2:	0204a423          	sw	zero,40(s1)
}
    800045c6:	60e2                	ld	ra,24(sp)
    800045c8:	6442                	ld	s0,16(sp)
    800045ca:	64a2                	ld	s1,8(sp)
    800045cc:	6902                	ld	s2,0(sp)
    800045ce:	6105                	addi	sp,sp,32
    800045d0:	8082                	ret

00000000800045d2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045d2:	1101                	addi	sp,sp,-32
    800045d4:	ec06                	sd	ra,24(sp)
    800045d6:	e822                	sd	s0,16(sp)
    800045d8:	e426                	sd	s1,8(sp)
    800045da:	e04a                	sd	s2,0(sp)
    800045dc:	1000                	addi	s0,sp,32
    800045de:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e0:	00850913          	addi	s2,a0,8
    800045e4:	854a                	mv	a0,s2
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	5f0080e7          	jalr	1520(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800045ee:	409c                	lw	a5,0(s1)
    800045f0:	cb89                	beqz	a5,80004602 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045f2:	85ca                	mv	a1,s2
    800045f4:	8526                	mv	a0,s1
    800045f6:	ffffe097          	auipc	ra,0xffffe
    800045fa:	d54080e7          	jalr	-684(ra) # 8000234a <sleep>
  while (lk->locked) {
    800045fe:	409c                	lw	a5,0(s1)
    80004600:	fbed                	bnez	a5,800045f2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004602:	4785                	li	a5,1
    80004604:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004606:	ffffd097          	auipc	ra,0xffffd
    8000460a:	480080e7          	jalr	1152(ra) # 80001a86 <myproc>
    8000460e:	5d1c                	lw	a5,56(a0)
    80004610:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	676080e7          	jalr	1654(ra) # 80000c8a <release>
}
    8000461c:	60e2                	ld	ra,24(sp)
    8000461e:	6442                	ld	s0,16(sp)
    80004620:	64a2                	ld	s1,8(sp)
    80004622:	6902                	ld	s2,0(sp)
    80004624:	6105                	addi	sp,sp,32
    80004626:	8082                	ret

0000000080004628 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004628:	1101                	addi	sp,sp,-32
    8000462a:	ec06                	sd	ra,24(sp)
    8000462c:	e822                	sd	s0,16(sp)
    8000462e:	e426                	sd	s1,8(sp)
    80004630:	e04a                	sd	s2,0(sp)
    80004632:	1000                	addi	s0,sp,32
    80004634:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004636:	00850913          	addi	s2,a0,8
    8000463a:	854a                	mv	a0,s2
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	59a080e7          	jalr	1434(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004644:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004648:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffe097          	auipc	ra,0xffffe
    80004652:	e82080e7          	jalr	-382(ra) # 800024d0 <wakeup>
  release(&lk->lk);
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	632080e7          	jalr	1586(ra) # 80000c8a <release>
}
    80004660:	60e2                	ld	ra,24(sp)
    80004662:	6442                	ld	s0,16(sp)
    80004664:	64a2                	ld	s1,8(sp)
    80004666:	6902                	ld	s2,0(sp)
    80004668:	6105                	addi	sp,sp,32
    8000466a:	8082                	ret

000000008000466c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000466c:	7179                	addi	sp,sp,-48
    8000466e:	f406                	sd	ra,40(sp)
    80004670:	f022                	sd	s0,32(sp)
    80004672:	ec26                	sd	s1,24(sp)
    80004674:	e84a                	sd	s2,16(sp)
    80004676:	e44e                	sd	s3,8(sp)
    80004678:	1800                	addi	s0,sp,48
    8000467a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000467c:	00850913          	addi	s2,a0,8
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	554080e7          	jalr	1364(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000468a:	409c                	lw	a5,0(s1)
    8000468c:	ef99                	bnez	a5,800046aa <holdingsleep+0x3e>
    8000468e:	4481                	li	s1,0
  release(&lk->lk);
    80004690:	854a                	mv	a0,s2
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	5f8080e7          	jalr	1528(ra) # 80000c8a <release>
  return r;
}
    8000469a:	8526                	mv	a0,s1
    8000469c:	70a2                	ld	ra,40(sp)
    8000469e:	7402                	ld	s0,32(sp)
    800046a0:	64e2                	ld	s1,24(sp)
    800046a2:	6942                	ld	s2,16(sp)
    800046a4:	69a2                	ld	s3,8(sp)
    800046a6:	6145                	addi	sp,sp,48
    800046a8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046aa:	0284a983          	lw	s3,40(s1)
    800046ae:	ffffd097          	auipc	ra,0xffffd
    800046b2:	3d8080e7          	jalr	984(ra) # 80001a86 <myproc>
    800046b6:	5d04                	lw	s1,56(a0)
    800046b8:	413484b3          	sub	s1,s1,s3
    800046bc:	0014b493          	seqz	s1,s1
    800046c0:	bfc1                	j	80004690 <holdingsleep+0x24>

00000000800046c2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046c2:	1141                	addi	sp,sp,-16
    800046c4:	e406                	sd	ra,8(sp)
    800046c6:	e022                	sd	s0,0(sp)
    800046c8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046ca:	00004597          	auipc	a1,0x4
    800046ce:	00e58593          	addi	a1,a1,14 # 800086d8 <syscalls+0x258>
    800046d2:	00029517          	auipc	a0,0x29
    800046d6:	cce50513          	addi	a0,a0,-818 # 8002d3a0 <ftable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	46c080e7          	jalr	1132(ra) # 80000b46 <initlock>
}
    800046e2:	60a2                	ld	ra,8(sp)
    800046e4:	6402                	ld	s0,0(sp)
    800046e6:	0141                	addi	sp,sp,16
    800046e8:	8082                	ret

00000000800046ea <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046ea:	1101                	addi	sp,sp,-32
    800046ec:	ec06                	sd	ra,24(sp)
    800046ee:	e822                	sd	s0,16(sp)
    800046f0:	e426                	sd	s1,8(sp)
    800046f2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046f4:	00029517          	auipc	a0,0x29
    800046f8:	cac50513          	addi	a0,a0,-852 # 8002d3a0 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	4da080e7          	jalr	1242(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004704:	00029497          	auipc	s1,0x29
    80004708:	cb448493          	addi	s1,s1,-844 # 8002d3b8 <ftable+0x18>
    8000470c:	0002a717          	auipc	a4,0x2a
    80004710:	c4c70713          	addi	a4,a4,-948 # 8002e358 <ftable+0xfb8>
    if(f->ref == 0){
    80004714:	40dc                	lw	a5,4(s1)
    80004716:	cf99                	beqz	a5,80004734 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004718:	02848493          	addi	s1,s1,40
    8000471c:	fee49ce3          	bne	s1,a4,80004714 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004720:	00029517          	auipc	a0,0x29
    80004724:	c8050513          	addi	a0,a0,-896 # 8002d3a0 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	562080e7          	jalr	1378(ra) # 80000c8a <release>
  return 0;
    80004730:	4481                	li	s1,0
    80004732:	a819                	j	80004748 <filealloc+0x5e>
      f->ref = 1;
    80004734:	4785                	li	a5,1
    80004736:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004738:	00029517          	auipc	a0,0x29
    8000473c:	c6850513          	addi	a0,a0,-920 # 8002d3a0 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	54a080e7          	jalr	1354(ra) # 80000c8a <release>
}
    80004748:	8526                	mv	a0,s1
    8000474a:	60e2                	ld	ra,24(sp)
    8000474c:	6442                	ld	s0,16(sp)
    8000474e:	64a2                	ld	s1,8(sp)
    80004750:	6105                	addi	sp,sp,32
    80004752:	8082                	ret

0000000080004754 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004754:	1101                	addi	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	e426                	sd	s1,8(sp)
    8000475c:	1000                	addi	s0,sp,32
    8000475e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004760:	00029517          	auipc	a0,0x29
    80004764:	c4050513          	addi	a0,a0,-960 # 8002d3a0 <ftable>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	46e080e7          	jalr	1134(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004770:	40dc                	lw	a5,4(s1)
    80004772:	02f05263          	blez	a5,80004796 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004776:	2785                	addiw	a5,a5,1
    80004778:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000477a:	00029517          	auipc	a0,0x29
    8000477e:	c2650513          	addi	a0,a0,-986 # 8002d3a0 <ftable>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	508080e7          	jalr	1288(ra) # 80000c8a <release>
  return f;
}
    8000478a:	8526                	mv	a0,s1
    8000478c:	60e2                	ld	ra,24(sp)
    8000478e:	6442                	ld	s0,16(sp)
    80004790:	64a2                	ld	s1,8(sp)
    80004792:	6105                	addi	sp,sp,32
    80004794:	8082                	ret
    panic("filedup");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	f4a50513          	addi	a0,a0,-182 # 800086e0 <syscalls+0x260>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	d92080e7          	jalr	-622(ra) # 80000530 <panic>

00000000800047a6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047a6:	7139                	addi	sp,sp,-64
    800047a8:	fc06                	sd	ra,56(sp)
    800047aa:	f822                	sd	s0,48(sp)
    800047ac:	f426                	sd	s1,40(sp)
    800047ae:	f04a                	sd	s2,32(sp)
    800047b0:	ec4e                	sd	s3,24(sp)
    800047b2:	e852                	sd	s4,16(sp)
    800047b4:	e456                	sd	s5,8(sp)
    800047b6:	0080                	addi	s0,sp,64
    800047b8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047ba:	00029517          	auipc	a0,0x29
    800047be:	be650513          	addi	a0,a0,-1050 # 8002d3a0 <ftable>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	414080e7          	jalr	1044(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047ca:	40dc                	lw	a5,4(s1)
    800047cc:	06f05163          	blez	a5,8000482e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047d0:	37fd                	addiw	a5,a5,-1
    800047d2:	0007871b          	sext.w	a4,a5
    800047d6:	c0dc                	sw	a5,4(s1)
    800047d8:	06e04363          	bgtz	a4,8000483e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047dc:	0004a903          	lw	s2,0(s1)
    800047e0:	0094ca83          	lbu	s5,9(s1)
    800047e4:	0104ba03          	ld	s4,16(s1)
    800047e8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047ec:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047f0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047f4:	00029517          	auipc	a0,0x29
    800047f8:	bac50513          	addi	a0,a0,-1108 # 8002d3a0 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	48e080e7          	jalr	1166(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004804:	4785                	li	a5,1
    80004806:	04f90d63          	beq	s2,a5,80004860 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000480a:	3979                	addiw	s2,s2,-2
    8000480c:	4785                	li	a5,1
    8000480e:	0527e063          	bltu	a5,s2,8000484e <fileclose+0xa8>
    begin_op();
    80004812:	00000097          	auipc	ra,0x0
    80004816:	ac0080e7          	jalr	-1344(ra) # 800042d2 <begin_op>
    iput(ff.ip);
    8000481a:	854e                	mv	a0,s3
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	29e080e7          	jalr	670(ra) # 80003aba <iput>
    end_op();
    80004824:	00000097          	auipc	ra,0x0
    80004828:	b2e080e7          	jalr	-1234(ra) # 80004352 <end_op>
    8000482c:	a00d                	j	8000484e <fileclose+0xa8>
    panic("fileclose");
    8000482e:	00004517          	auipc	a0,0x4
    80004832:	eba50513          	addi	a0,a0,-326 # 800086e8 <syscalls+0x268>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	cfa080e7          	jalr	-774(ra) # 80000530 <panic>
    release(&ftable.lock);
    8000483e:	00029517          	auipc	a0,0x29
    80004842:	b6250513          	addi	a0,a0,-1182 # 8002d3a0 <ftable>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	444080e7          	jalr	1092(ra) # 80000c8a <release>
  }
}
    8000484e:	70e2                	ld	ra,56(sp)
    80004850:	7442                	ld	s0,48(sp)
    80004852:	74a2                	ld	s1,40(sp)
    80004854:	7902                	ld	s2,32(sp)
    80004856:	69e2                	ld	s3,24(sp)
    80004858:	6a42                	ld	s4,16(sp)
    8000485a:	6aa2                	ld	s5,8(sp)
    8000485c:	6121                	addi	sp,sp,64
    8000485e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004860:	85d6                	mv	a1,s5
    80004862:	8552                	mv	a0,s4
    80004864:	00000097          	auipc	ra,0x0
    80004868:	34c080e7          	jalr	844(ra) # 80004bb0 <pipeclose>
    8000486c:	b7cd                	j	8000484e <fileclose+0xa8>

000000008000486e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000486e:	715d                	addi	sp,sp,-80
    80004870:	e486                	sd	ra,72(sp)
    80004872:	e0a2                	sd	s0,64(sp)
    80004874:	fc26                	sd	s1,56(sp)
    80004876:	f84a                	sd	s2,48(sp)
    80004878:	f44e                	sd	s3,40(sp)
    8000487a:	0880                	addi	s0,sp,80
    8000487c:	84aa                	mv	s1,a0
    8000487e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004880:	ffffd097          	auipc	ra,0xffffd
    80004884:	206080e7          	jalr	518(ra) # 80001a86 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004888:	409c                	lw	a5,0(s1)
    8000488a:	37f9                	addiw	a5,a5,-2
    8000488c:	4705                	li	a4,1
    8000488e:	04f76763          	bltu	a4,a5,800048dc <filestat+0x6e>
    80004892:	892a                	mv	s2,a0
    ilock(f->ip);
    80004894:	6c88                	ld	a0,24(s1)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	054080e7          	jalr	84(ra) # 800038ea <ilock>
    stati(f->ip, &st);
    8000489e:	fb840593          	addi	a1,s0,-72
    800048a2:	6c88                	ld	a0,24(s1)
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	2e6080e7          	jalr	742(ra) # 80003b8a <stati>
    iunlock(f->ip);
    800048ac:	6c88                	ld	a0,24(s1)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	114080e7          	jalr	276(ra) # 800039c2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048b6:	46e1                	li	a3,24
    800048b8:	fb840613          	addi	a2,s0,-72
    800048bc:	85ce                	mv	a1,s3
    800048be:	05093503          	ld	a0,80(s2)
    800048c2:	ffffd097          	auipc	ra,0xffffd
    800048c6:	d7a080e7          	jalr	-646(ra) # 8000163c <copyout>
    800048ca:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048ce:	60a6                	ld	ra,72(sp)
    800048d0:	6406                	ld	s0,64(sp)
    800048d2:	74e2                	ld	s1,56(sp)
    800048d4:	7942                	ld	s2,48(sp)
    800048d6:	79a2                	ld	s3,40(sp)
    800048d8:	6161                	addi	sp,sp,80
    800048da:	8082                	ret
  return -1;
    800048dc:	557d                	li	a0,-1
    800048de:	bfc5                	j	800048ce <filestat+0x60>

00000000800048e0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048e0:	7179                	addi	sp,sp,-48
    800048e2:	f406                	sd	ra,40(sp)
    800048e4:	f022                	sd	s0,32(sp)
    800048e6:	ec26                	sd	s1,24(sp)
    800048e8:	e84a                	sd	s2,16(sp)
    800048ea:	e44e                	sd	s3,8(sp)
    800048ec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048ee:	00854783          	lbu	a5,8(a0)
    800048f2:	c3d5                	beqz	a5,80004996 <fileread+0xb6>
    800048f4:	84aa                	mv	s1,a0
    800048f6:	89ae                	mv	s3,a1
    800048f8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048fa:	411c                	lw	a5,0(a0)
    800048fc:	4705                	li	a4,1
    800048fe:	04e78963          	beq	a5,a4,80004950 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004902:	470d                	li	a4,3
    80004904:	04e78d63          	beq	a5,a4,8000495e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004908:	4709                	li	a4,2
    8000490a:	06e79e63          	bne	a5,a4,80004986 <fileread+0xa6>
    ilock(f->ip);
    8000490e:	6d08                	ld	a0,24(a0)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	fda080e7          	jalr	-38(ra) # 800038ea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004918:	874a                	mv	a4,s2
    8000491a:	5094                	lw	a3,32(s1)
    8000491c:	864e                	mv	a2,s3
    8000491e:	4585                	li	a1,1
    80004920:	6c88                	ld	a0,24(s1)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	292080e7          	jalr	658(ra) # 80003bb4 <readi>
    8000492a:	892a                	mv	s2,a0
    8000492c:	00a05563          	blez	a0,80004936 <fileread+0x56>
      f->off += r;
    80004930:	509c                	lw	a5,32(s1)
    80004932:	9fa9                	addw	a5,a5,a0
    80004934:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004936:	6c88                	ld	a0,24(s1)
    80004938:	fffff097          	auipc	ra,0xfffff
    8000493c:	08a080e7          	jalr	138(ra) # 800039c2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004940:	854a                	mv	a0,s2
    80004942:	70a2                	ld	ra,40(sp)
    80004944:	7402                	ld	s0,32(sp)
    80004946:	64e2                	ld	s1,24(sp)
    80004948:	6942                	ld	s2,16(sp)
    8000494a:	69a2                	ld	s3,8(sp)
    8000494c:	6145                	addi	sp,sp,48
    8000494e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004950:	6908                	ld	a0,16(a0)
    80004952:	00000097          	auipc	ra,0x0
    80004956:	3c8080e7          	jalr	968(ra) # 80004d1a <piperead>
    8000495a:	892a                	mv	s2,a0
    8000495c:	b7d5                	j	80004940 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000495e:	02451783          	lh	a5,36(a0)
    80004962:	03079693          	slli	a3,a5,0x30
    80004966:	92c1                	srli	a3,a3,0x30
    80004968:	4725                	li	a4,9
    8000496a:	02d76863          	bltu	a4,a3,8000499a <fileread+0xba>
    8000496e:	0792                	slli	a5,a5,0x4
    80004970:	00029717          	auipc	a4,0x29
    80004974:	99070713          	addi	a4,a4,-1648 # 8002d300 <devsw>
    80004978:	97ba                	add	a5,a5,a4
    8000497a:	639c                	ld	a5,0(a5)
    8000497c:	c38d                	beqz	a5,8000499e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000497e:	4505                	li	a0,1
    80004980:	9782                	jalr	a5
    80004982:	892a                	mv	s2,a0
    80004984:	bf75                	j	80004940 <fileread+0x60>
    panic("fileread");
    80004986:	00004517          	auipc	a0,0x4
    8000498a:	d7250513          	addi	a0,a0,-654 # 800086f8 <syscalls+0x278>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	ba2080e7          	jalr	-1118(ra) # 80000530 <panic>
    return -1;
    80004996:	597d                	li	s2,-1
    80004998:	b765                	j	80004940 <fileread+0x60>
      return -1;
    8000499a:	597d                	li	s2,-1
    8000499c:	b755                	j	80004940 <fileread+0x60>
    8000499e:	597d                	li	s2,-1
    800049a0:	b745                	j	80004940 <fileread+0x60>

00000000800049a2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049a2:	715d                	addi	sp,sp,-80
    800049a4:	e486                	sd	ra,72(sp)
    800049a6:	e0a2                	sd	s0,64(sp)
    800049a8:	fc26                	sd	s1,56(sp)
    800049aa:	f84a                	sd	s2,48(sp)
    800049ac:	f44e                	sd	s3,40(sp)
    800049ae:	f052                	sd	s4,32(sp)
    800049b0:	ec56                	sd	s5,24(sp)
    800049b2:	e85a                	sd	s6,16(sp)
    800049b4:	e45e                	sd	s7,8(sp)
    800049b6:	e062                	sd	s8,0(sp)
    800049b8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049ba:	00954783          	lbu	a5,9(a0)
    800049be:	10078663          	beqz	a5,80004aca <filewrite+0x128>
    800049c2:	892a                	mv	s2,a0
    800049c4:	8aae                	mv	s5,a1
    800049c6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049c8:	411c                	lw	a5,0(a0)
    800049ca:	4705                	li	a4,1
    800049cc:	02e78263          	beq	a5,a4,800049f0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d0:	470d                	li	a4,3
    800049d2:	02e78663          	beq	a5,a4,800049fe <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049d6:	4709                	li	a4,2
    800049d8:	0ee79163          	bne	a5,a4,80004aba <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049dc:	0ac05d63          	blez	a2,80004a96 <filewrite+0xf4>
    int i = 0;
    800049e0:	4981                	li	s3,0
    800049e2:	6b05                	lui	s6,0x1
    800049e4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049e8:	6b85                	lui	s7,0x1
    800049ea:	c00b8b9b          	addiw	s7,s7,-1024
    800049ee:	a861                	j	80004a86 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049f0:	6908                	ld	a0,16(a0)
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	22e080e7          	jalr	558(ra) # 80004c20 <pipewrite>
    800049fa:	8a2a                	mv	s4,a0
    800049fc:	a045                	j	80004a9c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049fe:	02451783          	lh	a5,36(a0)
    80004a02:	03079693          	slli	a3,a5,0x30
    80004a06:	92c1                	srli	a3,a3,0x30
    80004a08:	4725                	li	a4,9
    80004a0a:	0cd76263          	bltu	a4,a3,80004ace <filewrite+0x12c>
    80004a0e:	0792                	slli	a5,a5,0x4
    80004a10:	00029717          	auipc	a4,0x29
    80004a14:	8f070713          	addi	a4,a4,-1808 # 8002d300 <devsw>
    80004a18:	97ba                	add	a5,a5,a4
    80004a1a:	679c                	ld	a5,8(a5)
    80004a1c:	cbdd                	beqz	a5,80004ad2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a1e:	4505                	li	a0,1
    80004a20:	9782                	jalr	a5
    80004a22:	8a2a                	mv	s4,a0
    80004a24:	a8a5                	j	80004a9c <filewrite+0xfa>
    80004a26:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	8a8080e7          	jalr	-1880(ra) # 800042d2 <begin_op>
      ilock(f->ip);
    80004a32:	01893503          	ld	a0,24(s2)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	eb4080e7          	jalr	-332(ra) # 800038ea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a3e:	8762                	mv	a4,s8
    80004a40:	02092683          	lw	a3,32(s2)
    80004a44:	01598633          	add	a2,s3,s5
    80004a48:	4585                	li	a1,1
    80004a4a:	01893503          	ld	a0,24(s2)
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	25e080e7          	jalr	606(ra) # 80003cac <writei>
    80004a56:	84aa                	mv	s1,a0
    80004a58:	00a05763          	blez	a0,80004a66 <filewrite+0xc4>
        f->off += r;
    80004a5c:	02092783          	lw	a5,32(s2)
    80004a60:	9fa9                	addw	a5,a5,a0
    80004a62:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a66:	01893503          	ld	a0,24(s2)
    80004a6a:	fffff097          	auipc	ra,0xfffff
    80004a6e:	f58080e7          	jalr	-168(ra) # 800039c2 <iunlock>
      end_op();
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	8e0080e7          	jalr	-1824(ra) # 80004352 <end_op>

      if(r != n1){
    80004a7a:	009c1f63          	bne	s8,s1,80004a98 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a7e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a82:	0149db63          	bge	s3,s4,80004a98 <filewrite+0xf6>
      int n1 = n - i;
    80004a86:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a8a:	84be                	mv	s1,a5
    80004a8c:	2781                	sext.w	a5,a5
    80004a8e:	f8fb5ce3          	bge	s6,a5,80004a26 <filewrite+0x84>
    80004a92:	84de                	mv	s1,s7
    80004a94:	bf49                	j	80004a26 <filewrite+0x84>
    int i = 0;
    80004a96:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a98:	013a1f63          	bne	s4,s3,80004ab6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a9c:	8552                	mv	a0,s4
    80004a9e:	60a6                	ld	ra,72(sp)
    80004aa0:	6406                	ld	s0,64(sp)
    80004aa2:	74e2                	ld	s1,56(sp)
    80004aa4:	7942                	ld	s2,48(sp)
    80004aa6:	79a2                	ld	s3,40(sp)
    80004aa8:	7a02                	ld	s4,32(sp)
    80004aaa:	6ae2                	ld	s5,24(sp)
    80004aac:	6b42                	ld	s6,16(sp)
    80004aae:	6ba2                	ld	s7,8(sp)
    80004ab0:	6c02                	ld	s8,0(sp)
    80004ab2:	6161                	addi	sp,sp,80
    80004ab4:	8082                	ret
    ret = (i == n ? n : -1);
    80004ab6:	5a7d                	li	s4,-1
    80004ab8:	b7d5                	j	80004a9c <filewrite+0xfa>
    panic("filewrite");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	c4e50513          	addi	a0,a0,-946 # 80008708 <syscalls+0x288>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a6e080e7          	jalr	-1426(ra) # 80000530 <panic>
    return -1;
    80004aca:	5a7d                	li	s4,-1
    80004acc:	bfc1                	j	80004a9c <filewrite+0xfa>
      return -1;
    80004ace:	5a7d                	li	s4,-1
    80004ad0:	b7f1                	j	80004a9c <filewrite+0xfa>
    80004ad2:	5a7d                	li	s4,-1
    80004ad4:	b7e1                	j	80004a9c <filewrite+0xfa>

0000000080004ad6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ad6:	7179                	addi	sp,sp,-48
    80004ad8:	f406                	sd	ra,40(sp)
    80004ada:	f022                	sd	s0,32(sp)
    80004adc:	ec26                	sd	s1,24(sp)
    80004ade:	e84a                	sd	s2,16(sp)
    80004ae0:	e44e                	sd	s3,8(sp)
    80004ae2:	e052                	sd	s4,0(sp)
    80004ae4:	1800                	addi	s0,sp,48
    80004ae6:	84aa                	mv	s1,a0
    80004ae8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aea:	0005b023          	sd	zero,0(a1)
    80004aee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	bf8080e7          	jalr	-1032(ra) # 800046ea <filealloc>
    80004afa:	e088                	sd	a0,0(s1)
    80004afc:	c551                	beqz	a0,80004b88 <pipealloc+0xb2>
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	bec080e7          	jalr	-1044(ra) # 800046ea <filealloc>
    80004b06:	00aa3023          	sd	a0,0(s4)
    80004b0a:	c92d                	beqz	a0,80004b7c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	fda080e7          	jalr	-38(ra) # 80000ae6 <kalloc>
    80004b14:	892a                	mv	s2,a0
    80004b16:	c125                	beqz	a0,80004b76 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b18:	4985                	li	s3,1
    80004b1a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b1e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b22:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b26:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b2a:	00004597          	auipc	a1,0x4
    80004b2e:	bee58593          	addi	a1,a1,-1042 # 80008718 <syscalls+0x298>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	014080e7          	jalr	20(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b3a:	609c                	ld	a5,0(s1)
    80004b3c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b40:	609c                	ld	a5,0(s1)
    80004b42:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b46:	609c                	ld	a5,0(s1)
    80004b48:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b4c:	609c                	ld	a5,0(s1)
    80004b4e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b52:	000a3783          	ld	a5,0(s4)
    80004b56:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b5a:	000a3783          	ld	a5,0(s4)
    80004b5e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b62:	000a3783          	ld	a5,0(s4)
    80004b66:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b6a:	000a3783          	ld	a5,0(s4)
    80004b6e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b72:	4501                	li	a0,0
    80004b74:	a025                	j	80004b9c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b76:	6088                	ld	a0,0(s1)
    80004b78:	e501                	bnez	a0,80004b80 <pipealloc+0xaa>
    80004b7a:	a039                	j	80004b88 <pipealloc+0xb2>
    80004b7c:	6088                	ld	a0,0(s1)
    80004b7e:	c51d                	beqz	a0,80004bac <pipealloc+0xd6>
    fileclose(*f0);
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	c26080e7          	jalr	-986(ra) # 800047a6 <fileclose>
  if(*f1)
    80004b88:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b8c:	557d                	li	a0,-1
  if(*f1)
    80004b8e:	c799                	beqz	a5,80004b9c <pipealloc+0xc6>
    fileclose(*f1);
    80004b90:	853e                	mv	a0,a5
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	c14080e7          	jalr	-1004(ra) # 800047a6 <fileclose>
  return -1;
    80004b9a:	557d                	li	a0,-1
}
    80004b9c:	70a2                	ld	ra,40(sp)
    80004b9e:	7402                	ld	s0,32(sp)
    80004ba0:	64e2                	ld	s1,24(sp)
    80004ba2:	6942                	ld	s2,16(sp)
    80004ba4:	69a2                	ld	s3,8(sp)
    80004ba6:	6a02                	ld	s4,0(sp)
    80004ba8:	6145                	addi	sp,sp,48
    80004baa:	8082                	ret
  return -1;
    80004bac:	557d                	li	a0,-1
    80004bae:	b7fd                	j	80004b9c <pipealloc+0xc6>

0000000080004bb0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bb0:	1101                	addi	sp,sp,-32
    80004bb2:	ec06                	sd	ra,24(sp)
    80004bb4:	e822                	sd	s0,16(sp)
    80004bb6:	e426                	sd	s1,8(sp)
    80004bb8:	e04a                	sd	s2,0(sp)
    80004bba:	1000                	addi	s0,sp,32
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
  if(writable){
    80004bc8:	02090d63          	beqz	s2,80004c02 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bcc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bd0:	21848513          	addi	a0,s1,536
    80004bd4:	ffffe097          	auipc	ra,0xffffe
    80004bd8:	8fc080e7          	jalr	-1796(ra) # 800024d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bdc:	2204b783          	ld	a5,544(s1)
    80004be0:	eb95                	bnez	a5,80004c14 <pipeclose+0x64>
    release(&pi->lock);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0a6080e7          	jalr	166(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	dfc080e7          	jalr	-516(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004bf6:	60e2                	ld	ra,24(sp)
    80004bf8:	6442                	ld	s0,16(sp)
    80004bfa:	64a2                	ld	s1,8(sp)
    80004bfc:	6902                	ld	s2,0(sp)
    80004bfe:	6105                	addi	sp,sp,32
    80004c00:	8082                	ret
    pi->readopen = 0;
    80004c02:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c06:	21c48513          	addi	a0,s1,540
    80004c0a:	ffffe097          	auipc	ra,0xffffe
    80004c0e:	8c6080e7          	jalr	-1850(ra) # 800024d0 <wakeup>
    80004c12:	b7e9                	j	80004bdc <pipeclose+0x2c>
    release(&pi->lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	074080e7          	jalr	116(ra) # 80000c8a <release>
}
    80004c1e:	bfe1                	j	80004bf6 <pipeclose+0x46>

0000000080004c20 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c20:	7159                	addi	sp,sp,-112
    80004c22:	f486                	sd	ra,104(sp)
    80004c24:	f0a2                	sd	s0,96(sp)
    80004c26:	eca6                	sd	s1,88(sp)
    80004c28:	e8ca                	sd	s2,80(sp)
    80004c2a:	e4ce                	sd	s3,72(sp)
    80004c2c:	e0d2                	sd	s4,64(sp)
    80004c2e:	fc56                	sd	s5,56(sp)
    80004c30:	f85a                	sd	s6,48(sp)
    80004c32:	f45e                	sd	s7,40(sp)
    80004c34:	f062                	sd	s8,32(sp)
    80004c36:	ec66                	sd	s9,24(sp)
    80004c38:	1880                	addi	s0,sp,112
    80004c3a:	84aa                	mv	s1,a0
    80004c3c:	8aae                	mv	s5,a1
    80004c3e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	e46080e7          	jalr	-442(ra) # 80001a86 <myproc>
    80004c48:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	f8a080e7          	jalr	-118(ra) # 80000bd6 <acquire>
  while(i < n){
    80004c54:	0d405163          	blez	s4,80004d16 <pipewrite+0xf6>
    80004c58:	8ba6                	mv	s7,s1
  int i = 0;
    80004c5a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c5c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c5e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c62:	21c48c13          	addi	s8,s1,540
    80004c66:	a08d                	j	80004cc8 <pipewrite+0xa8>
      release(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
      return -1;
    80004c72:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c74:	854a                	mv	a0,s2
    80004c76:	70a6                	ld	ra,104(sp)
    80004c78:	7406                	ld	s0,96(sp)
    80004c7a:	64e6                	ld	s1,88(sp)
    80004c7c:	6946                	ld	s2,80(sp)
    80004c7e:	69a6                	ld	s3,72(sp)
    80004c80:	6a06                	ld	s4,64(sp)
    80004c82:	7ae2                	ld	s5,56(sp)
    80004c84:	7b42                	ld	s6,48(sp)
    80004c86:	7ba2                	ld	s7,40(sp)
    80004c88:	7c02                	ld	s8,32(sp)
    80004c8a:	6ce2                	ld	s9,24(sp)
    80004c8c:	6165                	addi	sp,sp,112
    80004c8e:	8082                	ret
      wakeup(&pi->nread);
    80004c90:	8566                	mv	a0,s9
    80004c92:	ffffe097          	auipc	ra,0xffffe
    80004c96:	83e080e7          	jalr	-1986(ra) # 800024d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c9a:	85de                	mv	a1,s7
    80004c9c:	8562                	mv	a0,s8
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	6ac080e7          	jalr	1708(ra) # 8000234a <sleep>
    80004ca6:	a839                	j	80004cc4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ca8:	21c4a783          	lw	a5,540(s1)
    80004cac:	0017871b          	addiw	a4,a5,1
    80004cb0:	20e4ae23          	sw	a4,540(s1)
    80004cb4:	1ff7f793          	andi	a5,a5,511
    80004cb8:	97a6                	add	a5,a5,s1
    80004cba:	f9f44703          	lbu	a4,-97(s0)
    80004cbe:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cc2:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cc4:	03495d63          	bge	s2,s4,80004cfe <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004cc8:	2204a783          	lw	a5,544(s1)
    80004ccc:	dfd1                	beqz	a5,80004c68 <pipewrite+0x48>
    80004cce:	0309a783          	lw	a5,48(s3)
    80004cd2:	fbd9                	bnez	a5,80004c68 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cd4:	2184a783          	lw	a5,536(s1)
    80004cd8:	21c4a703          	lw	a4,540(s1)
    80004cdc:	2007879b          	addiw	a5,a5,512
    80004ce0:	faf708e3          	beq	a4,a5,80004c90 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce4:	4685                	li	a3,1
    80004ce6:	01590633          	add	a2,s2,s5
    80004cea:	f9f40593          	addi	a1,s0,-97
    80004cee:	0509b503          	ld	a0,80(s3)
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	9d6080e7          	jalr	-1578(ra) # 800016c8 <copyin>
    80004cfa:	fb6517e3          	bne	a0,s6,80004ca8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cfe:	21848513          	addi	a0,s1,536
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	7ce080e7          	jalr	1998(ra) # 800024d0 <wakeup>
  release(&pi->lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	f7e080e7          	jalr	-130(ra) # 80000c8a <release>
  return i;
    80004d14:	b785                	j	80004c74 <pipewrite+0x54>
  int i = 0;
    80004d16:	4901                	li	s2,0
    80004d18:	b7dd                	j	80004cfe <pipewrite+0xde>

0000000080004d1a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d1a:	715d                	addi	sp,sp,-80
    80004d1c:	e486                	sd	ra,72(sp)
    80004d1e:	e0a2                	sd	s0,64(sp)
    80004d20:	fc26                	sd	s1,56(sp)
    80004d22:	f84a                	sd	s2,48(sp)
    80004d24:	f44e                	sd	s3,40(sp)
    80004d26:	f052                	sd	s4,32(sp)
    80004d28:	ec56                	sd	s5,24(sp)
    80004d2a:	e85a                	sd	s6,16(sp)
    80004d2c:	0880                	addi	s0,sp,80
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	892e                	mv	s2,a1
    80004d32:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	d52080e7          	jalr	-686(ra) # 80001a86 <myproc>
    80004d3c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d3e:	8b26                	mv	s6,s1
    80004d40:	8526                	mv	a0,s1
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	e94080e7          	jalr	-364(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4a:	2184a703          	lw	a4,536(s1)
    80004d4e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d52:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d56:	02f71463          	bne	a4,a5,80004d7e <piperead+0x64>
    80004d5a:	2244a783          	lw	a5,548(s1)
    80004d5e:	c385                	beqz	a5,80004d7e <piperead+0x64>
    if(pr->killed){
    80004d60:	030a2783          	lw	a5,48(s4)
    80004d64:	ebc1                	bnez	a5,80004df4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d66:	85da                	mv	a1,s6
    80004d68:	854e                	mv	a0,s3
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	5e0080e7          	jalr	1504(ra) # 8000234a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d72:	2184a703          	lw	a4,536(s1)
    80004d76:	21c4a783          	lw	a5,540(s1)
    80004d7a:	fef700e3          	beq	a4,a5,80004d5a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7e:	09505263          	blez	s5,80004e02 <piperead+0xe8>
    80004d82:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d84:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d86:	2184a783          	lw	a5,536(s1)
    80004d8a:	21c4a703          	lw	a4,540(s1)
    80004d8e:	02f70d63          	beq	a4,a5,80004dc8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d92:	0017871b          	addiw	a4,a5,1
    80004d96:	20e4ac23          	sw	a4,536(s1)
    80004d9a:	1ff7f793          	andi	a5,a5,511
    80004d9e:	97a6                	add	a5,a5,s1
    80004da0:	0187c783          	lbu	a5,24(a5)
    80004da4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da8:	4685                	li	a3,1
    80004daa:	fbf40613          	addi	a2,s0,-65
    80004dae:	85ca                	mv	a1,s2
    80004db0:	050a3503          	ld	a0,80(s4)
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	888080e7          	jalr	-1912(ra) # 8000163c <copyout>
    80004dbc:	01650663          	beq	a0,s6,80004dc8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc0:	2985                	addiw	s3,s3,1
    80004dc2:	0905                	addi	s2,s2,1
    80004dc4:	fd3a91e3          	bne	s5,s3,80004d86 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dc8:	21c48513          	addi	a0,s1,540
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	704080e7          	jalr	1796(ra) # 800024d0 <wakeup>
  release(&pi->lock);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>
  return i;
}
    80004dde:	854e                	mv	a0,s3
    80004de0:	60a6                	ld	ra,72(sp)
    80004de2:	6406                	ld	s0,64(sp)
    80004de4:	74e2                	ld	s1,56(sp)
    80004de6:	7942                	ld	s2,48(sp)
    80004de8:	79a2                	ld	s3,40(sp)
    80004dea:	7a02                	ld	s4,32(sp)
    80004dec:	6ae2                	ld	s5,24(sp)
    80004dee:	6b42                	ld	s6,16(sp)
    80004df0:	6161                	addi	sp,sp,80
    80004df2:	8082                	ret
      release(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	e94080e7          	jalr	-364(ra) # 80000c8a <release>
      return -1;
    80004dfe:	59fd                	li	s3,-1
    80004e00:	bff9                	j	80004dde <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e02:	4981                	li	s3,0
    80004e04:	b7d1                	j	80004dc8 <piperead+0xae>

0000000080004e06 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e06:	df010113          	addi	sp,sp,-528
    80004e0a:	20113423          	sd	ra,520(sp)
    80004e0e:	20813023          	sd	s0,512(sp)
    80004e12:	ffa6                	sd	s1,504(sp)
    80004e14:	fbca                	sd	s2,496(sp)
    80004e16:	f7ce                	sd	s3,488(sp)
    80004e18:	f3d2                	sd	s4,480(sp)
    80004e1a:	efd6                	sd	s5,472(sp)
    80004e1c:	ebda                	sd	s6,464(sp)
    80004e1e:	e7de                	sd	s7,456(sp)
    80004e20:	e3e2                	sd	s8,448(sp)
    80004e22:	ff66                	sd	s9,440(sp)
    80004e24:	fb6a                	sd	s10,432(sp)
    80004e26:	f76e                	sd	s11,424(sp)
    80004e28:	0c00                	addi	s0,sp,528
    80004e2a:	84aa                	mv	s1,a0
    80004e2c:	dea43c23          	sd	a0,-520(s0)
    80004e30:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	c52080e7          	jalr	-942(ra) # 80001a86 <myproc>
    80004e3c:	892a                	mv	s2,a0

  begin_op();
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	494080e7          	jalr	1172(ra) # 800042d2 <begin_op>

  if((ip = namei(path)) == 0){
    80004e46:	8526                	mv	a0,s1
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	26e080e7          	jalr	622(ra) # 800040b6 <namei>
    80004e50:	c92d                	beqz	a0,80004ec2 <exec+0xbc>
    80004e52:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	a96080e7          	jalr	-1386(ra) # 800038ea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e5c:	04000713          	li	a4,64
    80004e60:	4681                	li	a3,0
    80004e62:	e4840613          	addi	a2,s0,-440
    80004e66:	4581                	li	a1,0
    80004e68:	8526                	mv	a0,s1
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	d4a080e7          	jalr	-694(ra) # 80003bb4 <readi>
    80004e72:	04000793          	li	a5,64
    80004e76:	00f51a63          	bne	a0,a5,80004e8a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e7a:	e4842703          	lw	a4,-440(s0)
    80004e7e:	464c47b7          	lui	a5,0x464c4
    80004e82:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e86:	04f70463          	beq	a4,a5,80004ece <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	cd6080e7          	jalr	-810(ra) # 80003b62 <iunlockput>
    end_op();
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	4be080e7          	jalr	1214(ra) # 80004352 <end_op>
  }
  return -1;
    80004e9c:	557d                	li	a0,-1
}
    80004e9e:	20813083          	ld	ra,520(sp)
    80004ea2:	20013403          	ld	s0,512(sp)
    80004ea6:	74fe                	ld	s1,504(sp)
    80004ea8:	795e                	ld	s2,496(sp)
    80004eaa:	79be                	ld	s3,488(sp)
    80004eac:	7a1e                	ld	s4,480(sp)
    80004eae:	6afe                	ld	s5,472(sp)
    80004eb0:	6b5e                	ld	s6,464(sp)
    80004eb2:	6bbe                	ld	s7,456(sp)
    80004eb4:	6c1e                	ld	s8,448(sp)
    80004eb6:	7cfa                	ld	s9,440(sp)
    80004eb8:	7d5a                	ld	s10,432(sp)
    80004eba:	7dba                	ld	s11,424(sp)
    80004ebc:	21010113          	addi	sp,sp,528
    80004ec0:	8082                	ret
    end_op();
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	490080e7          	jalr	1168(ra) # 80004352 <end_op>
    return -1;
    80004eca:	557d                	li	a0,-1
    80004ecc:	bfc9                	j	80004e9e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ece:	854a                	mv	a0,s2
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	c7a080e7          	jalr	-902(ra) # 80001b4a <proc_pagetable>
    80004ed8:	8baa                	mv	s7,a0
    80004eda:	d945                	beqz	a0,80004e8a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004edc:	e6842983          	lw	s3,-408(s0)
    80004ee0:	e8045783          	lhu	a5,-384(s0)
    80004ee4:	c7ad                	beqz	a5,80004f4e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ee6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004eea:	6c85                	lui	s9,0x1
    80004eec:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ef0:	def43823          	sd	a5,-528(s0)
    80004ef4:	a42d                	j	8000511e <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ef6:	00004517          	auipc	a0,0x4
    80004efa:	82a50513          	addi	a0,a0,-2006 # 80008720 <syscalls+0x2a0>
    80004efe:	ffffb097          	auipc	ra,0xffffb
    80004f02:	632080e7          	jalr	1586(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f06:	8756                	mv	a4,s5
    80004f08:	012d86bb          	addw	a3,s11,s2
    80004f0c:	4581                	li	a1,0
    80004f0e:	8526                	mv	a0,s1
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	ca4080e7          	jalr	-860(ra) # 80003bb4 <readi>
    80004f18:	2501                	sext.w	a0,a0
    80004f1a:	1aaa9963          	bne	s5,a0,800050cc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f1e:	6785                	lui	a5,0x1
    80004f20:	0127893b          	addw	s2,a5,s2
    80004f24:	77fd                	lui	a5,0xfffff
    80004f26:	01478a3b          	addw	s4,a5,s4
    80004f2a:	1f897163          	bgeu	s2,s8,8000510c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f2e:	02091593          	slli	a1,s2,0x20
    80004f32:	9181                	srli	a1,a1,0x20
    80004f34:	95ea                	add	a1,a1,s10
    80004f36:	855e                	mv	a0,s7
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	12c080e7          	jalr	300(ra) # 80001064 <walkaddr>
    80004f40:	862a                	mv	a2,a0
    if(pa == 0)
    80004f42:	d955                	beqz	a0,80004ef6 <exec+0xf0>
      n = PGSIZE;
    80004f44:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f46:	fd9a70e3          	bgeu	s4,s9,80004f06 <exec+0x100>
      n = sz - i;
    80004f4a:	8ad2                	mv	s5,s4
    80004f4c:	bf6d                	j	80004f06 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f4e:	4901                	li	s2,0
  iunlockput(ip);
    80004f50:	8526                	mv	a0,s1
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	c10080e7          	jalr	-1008(ra) # 80003b62 <iunlockput>
  end_op();
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	3f8080e7          	jalr	1016(ra) # 80004352 <end_op>
  p = myproc();
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	b24080e7          	jalr	-1244(ra) # 80001a86 <myproc>
    80004f6a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f6c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f70:	6785                	lui	a5,0x1
    80004f72:	17fd                	addi	a5,a5,-1
    80004f74:	993e                	add	s2,s2,a5
    80004f76:	757d                	lui	a0,0xfffff
    80004f78:	00a977b3          	and	a5,s2,a0
    80004f7c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f80:	6609                	lui	a2,0x2
    80004f82:	963e                	add	a2,a2,a5
    80004f84:	85be                	mv	a1,a5
    80004f86:	855e                	mv	a0,s7
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	470080e7          	jalr	1136(ra) # 800013f8 <uvmalloc>
    80004f90:	8b2a                	mv	s6,a0
  ip = 0;
    80004f92:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f94:	12050c63          	beqz	a0,800050cc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f98:	75f9                	lui	a1,0xffffe
    80004f9a:	95aa                	add	a1,a1,a0
    80004f9c:	855e                	mv	a0,s7
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	66c080e7          	jalr	1644(ra) # 8000160a <uvmclear>
  stackbase = sp - PGSIZE;
    80004fa6:	7c7d                	lui	s8,0xfffff
    80004fa8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004faa:	e0043783          	ld	a5,-512(s0)
    80004fae:	6388                	ld	a0,0(a5)
    80004fb0:	c535                	beqz	a0,8000501c <exec+0x216>
    80004fb2:	e8840993          	addi	s3,s0,-376
    80004fb6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fba:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	e9e080e7          	jalr	-354(ra) # 80000e5a <strlen>
    80004fc4:	2505                	addiw	a0,a0,1
    80004fc6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fca:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fce:	13896363          	bltu	s2,s8,800050f4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fd2:	e0043d83          	ld	s11,-512(s0)
    80004fd6:	000dba03          	ld	s4,0(s11)
    80004fda:	8552                	mv	a0,s4
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	e7e080e7          	jalr	-386(ra) # 80000e5a <strlen>
    80004fe4:	0015069b          	addiw	a3,a0,1
    80004fe8:	8652                	mv	a2,s4
    80004fea:	85ca                	mv	a1,s2
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	64e080e7          	jalr	1614(ra) # 8000163c <copyout>
    80004ff6:	10054363          	bltz	a0,800050fc <exec+0x2f6>
    ustack[argc] = sp;
    80004ffa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ffe:	0485                	addi	s1,s1,1
    80005000:	008d8793          	addi	a5,s11,8
    80005004:	e0f43023          	sd	a5,-512(s0)
    80005008:	008db503          	ld	a0,8(s11)
    8000500c:	c911                	beqz	a0,80005020 <exec+0x21a>
    if(argc >= MAXARG)
    8000500e:	09a1                	addi	s3,s3,8
    80005010:	fb3c96e3          	bne	s9,s3,80004fbc <exec+0x1b6>
  sz = sz1;
    80005014:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005018:	4481                	li	s1,0
    8000501a:	a84d                	j	800050cc <exec+0x2c6>
  sp = sz;
    8000501c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000501e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005020:	00349793          	slli	a5,s1,0x3
    80005024:	f9040713          	addi	a4,s0,-112
    80005028:	97ba                	add	a5,a5,a4
    8000502a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000502e:	00148693          	addi	a3,s1,1
    80005032:	068e                	slli	a3,a3,0x3
    80005034:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005038:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000503c:	01897663          	bgeu	s2,s8,80005048 <exec+0x242>
  sz = sz1;
    80005040:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005044:	4481                	li	s1,0
    80005046:	a059                	j	800050cc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005048:	e8840613          	addi	a2,s0,-376
    8000504c:	85ca                	mv	a1,s2
    8000504e:	855e                	mv	a0,s7
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	5ec080e7          	jalr	1516(ra) # 8000163c <copyout>
    80005058:	0a054663          	bltz	a0,80005104 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000505c:	058ab783          	ld	a5,88(s5)
    80005060:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005064:	df843783          	ld	a5,-520(s0)
    80005068:	0007c703          	lbu	a4,0(a5)
    8000506c:	cf11                	beqz	a4,80005088 <exec+0x282>
    8000506e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005070:	02f00693          	li	a3,47
    80005074:	a029                	j	8000507e <exec+0x278>
  for(last=s=path; *s; s++)
    80005076:	0785                	addi	a5,a5,1
    80005078:	fff7c703          	lbu	a4,-1(a5)
    8000507c:	c711                	beqz	a4,80005088 <exec+0x282>
    if(*s == '/')
    8000507e:	fed71ce3          	bne	a4,a3,80005076 <exec+0x270>
      last = s+1;
    80005082:	def43c23          	sd	a5,-520(s0)
    80005086:	bfc5                	j	80005076 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005088:	4641                	li	a2,16
    8000508a:	df843583          	ld	a1,-520(s0)
    8000508e:	158a8513          	addi	a0,s5,344
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	d96080e7          	jalr	-618(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    8000509a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000509e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050a2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050a6:	058ab783          	ld	a5,88(s5)
    800050aa:	e6043703          	ld	a4,-416(s0)
    800050ae:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050b0:	058ab783          	ld	a5,88(s5)
    800050b4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050b8:	85ea                	mv	a1,s10
    800050ba:	ffffd097          	auipc	ra,0xffffd
    800050be:	b2c080e7          	jalr	-1236(ra) # 80001be6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050c2:	0004851b          	sext.w	a0,s1
    800050c6:	bbe1                	j	80004e9e <exec+0x98>
    800050c8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050cc:	e0843583          	ld	a1,-504(s0)
    800050d0:	855e                	mv	a0,s7
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	b14080e7          	jalr	-1260(ra) # 80001be6 <proc_freepagetable>
  if(ip){
    800050da:	da0498e3          	bnez	s1,80004e8a <exec+0x84>
  return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	bb7d                	j	80004e9e <exec+0x98>
    800050e2:	e1243423          	sd	s2,-504(s0)
    800050e6:	b7dd                	j	800050cc <exec+0x2c6>
    800050e8:	e1243423          	sd	s2,-504(s0)
    800050ec:	b7c5                	j	800050cc <exec+0x2c6>
    800050ee:	e1243423          	sd	s2,-504(s0)
    800050f2:	bfe9                	j	800050cc <exec+0x2c6>
  sz = sz1;
    800050f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f8:	4481                	li	s1,0
    800050fa:	bfc9                	j	800050cc <exec+0x2c6>
  sz = sz1;
    800050fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005100:	4481                	li	s1,0
    80005102:	b7e9                	j	800050cc <exec+0x2c6>
  sz = sz1;
    80005104:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005108:	4481                	li	s1,0
    8000510a:	b7c9                	j	800050cc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000510c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005110:	2b05                	addiw	s6,s6,1
    80005112:	0389899b          	addiw	s3,s3,56
    80005116:	e8045783          	lhu	a5,-384(s0)
    8000511a:	e2fb5be3          	bge	s6,a5,80004f50 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000511e:	2981                	sext.w	s3,s3
    80005120:	03800713          	li	a4,56
    80005124:	86ce                	mv	a3,s3
    80005126:	e1040613          	addi	a2,s0,-496
    8000512a:	4581                	li	a1,0
    8000512c:	8526                	mv	a0,s1
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	a86080e7          	jalr	-1402(ra) # 80003bb4 <readi>
    80005136:	03800793          	li	a5,56
    8000513a:	f8f517e3          	bne	a0,a5,800050c8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000513e:	e1042783          	lw	a5,-496(s0)
    80005142:	4705                	li	a4,1
    80005144:	fce796e3          	bne	a5,a4,80005110 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005148:	e3843603          	ld	a2,-456(s0)
    8000514c:	e3043783          	ld	a5,-464(s0)
    80005150:	f8f669e3          	bltu	a2,a5,800050e2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005154:	e2043783          	ld	a5,-480(s0)
    80005158:	963e                	add	a2,a2,a5
    8000515a:	f8f667e3          	bltu	a2,a5,800050e8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000515e:	85ca                	mv	a1,s2
    80005160:	855e                	mv	a0,s7
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	296080e7          	jalr	662(ra) # 800013f8 <uvmalloc>
    8000516a:	e0a43423          	sd	a0,-504(s0)
    8000516e:	d141                	beqz	a0,800050ee <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005170:	e2043d03          	ld	s10,-480(s0)
    80005174:	df043783          	ld	a5,-528(s0)
    80005178:	00fd77b3          	and	a5,s10,a5
    8000517c:	fba1                	bnez	a5,800050cc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000517e:	e1842d83          	lw	s11,-488(s0)
    80005182:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005186:	f80c03e3          	beqz	s8,8000510c <exec+0x306>
    8000518a:	8a62                	mv	s4,s8
    8000518c:	4901                	li	s2,0
    8000518e:	b345                	j	80004f2e <exec+0x128>

0000000080005190 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005190:	7179                	addi	sp,sp,-48
    80005192:	f406                	sd	ra,40(sp)
    80005194:	f022                	sd	s0,32(sp)
    80005196:	ec26                	sd	s1,24(sp)
    80005198:	e84a                	sd	s2,16(sp)
    8000519a:	1800                	addi	s0,sp,48
    8000519c:	892e                	mv	s2,a1
    8000519e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051a0:	fdc40593          	addi	a1,s0,-36
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	bd4080e7          	jalr	-1068(ra) # 80002d78 <argint>
    800051ac:	04054063          	bltz	a0,800051ec <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051b0:	fdc42703          	lw	a4,-36(s0)
    800051b4:	47bd                	li	a5,15
    800051b6:	02e7ed63          	bltu	a5,a4,800051f0 <argfd+0x60>
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	8cc080e7          	jalr	-1844(ra) # 80001a86 <myproc>
    800051c2:	fdc42703          	lw	a4,-36(s0)
    800051c6:	01a70793          	addi	a5,a4,26
    800051ca:	078e                	slli	a5,a5,0x3
    800051cc:	953e                	add	a0,a0,a5
    800051ce:	611c                	ld	a5,0(a0)
    800051d0:	c395                	beqz	a5,800051f4 <argfd+0x64>
    return -1;
  if(pfd)
    800051d2:	00090463          	beqz	s2,800051da <argfd+0x4a>
    *pfd = fd;
    800051d6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051da:	4501                	li	a0,0
  if(pf)
    800051dc:	c091                	beqz	s1,800051e0 <argfd+0x50>
    *pf = f;
    800051de:	e09c                	sd	a5,0(s1)
}
    800051e0:	70a2                	ld	ra,40(sp)
    800051e2:	7402                	ld	s0,32(sp)
    800051e4:	64e2                	ld	s1,24(sp)
    800051e6:	6942                	ld	s2,16(sp)
    800051e8:	6145                	addi	sp,sp,48
    800051ea:	8082                	ret
    return -1;
    800051ec:	557d                	li	a0,-1
    800051ee:	bfcd                	j	800051e0 <argfd+0x50>
    return -1;
    800051f0:	557d                	li	a0,-1
    800051f2:	b7fd                	j	800051e0 <argfd+0x50>
    800051f4:	557d                	li	a0,-1
    800051f6:	b7ed                	j	800051e0 <argfd+0x50>

00000000800051f8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051f8:	1101                	addi	sp,sp,-32
    800051fa:	ec06                	sd	ra,24(sp)
    800051fc:	e822                	sd	s0,16(sp)
    800051fe:	e426                	sd	s1,8(sp)
    80005200:	1000                	addi	s0,sp,32
    80005202:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	882080e7          	jalr	-1918(ra) # 80001a86 <myproc>
    8000520c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000520e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffcd0d0>
    80005212:	4501                	li	a0,0
    80005214:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005216:	6398                	ld	a4,0(a5)
    80005218:	cb19                	beqz	a4,8000522e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000521a:	2505                	addiw	a0,a0,1
    8000521c:	07a1                	addi	a5,a5,8
    8000521e:	fed51ce3          	bne	a0,a3,80005216 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005222:	557d                	li	a0,-1
}
    80005224:	60e2                	ld	ra,24(sp)
    80005226:	6442                	ld	s0,16(sp)
    80005228:	64a2                	ld	s1,8(sp)
    8000522a:	6105                	addi	sp,sp,32
    8000522c:	8082                	ret
      p->ofile[fd] = f;
    8000522e:	01a50793          	addi	a5,a0,26
    80005232:	078e                	slli	a5,a5,0x3
    80005234:	963e                	add	a2,a2,a5
    80005236:	e204                	sd	s1,0(a2)
      return fd;
    80005238:	b7f5                	j	80005224 <fdalloc+0x2c>

000000008000523a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000523a:	715d                	addi	sp,sp,-80
    8000523c:	e486                	sd	ra,72(sp)
    8000523e:	e0a2                	sd	s0,64(sp)
    80005240:	fc26                	sd	s1,56(sp)
    80005242:	f84a                	sd	s2,48(sp)
    80005244:	f44e                	sd	s3,40(sp)
    80005246:	f052                	sd	s4,32(sp)
    80005248:	ec56                	sd	s5,24(sp)
    8000524a:	0880                	addi	s0,sp,80
    8000524c:	89ae                	mv	s3,a1
    8000524e:	8ab2                	mv	s5,a2
    80005250:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005252:	fb040593          	addi	a1,s0,-80
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	e7e080e7          	jalr	-386(ra) # 800040d4 <nameiparent>
    8000525e:	892a                	mv	s2,a0
    80005260:	12050f63          	beqz	a0,8000539e <create+0x164>
    return 0;

  ilock(dp);
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	686080e7          	jalr	1670(ra) # 800038ea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000526c:	4601                	li	a2,0
    8000526e:	fb040593          	addi	a1,s0,-80
    80005272:	854a                	mv	a0,s2
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	b70080e7          	jalr	-1168(ra) # 80003de4 <dirlookup>
    8000527c:	84aa                	mv	s1,a0
    8000527e:	c921                	beqz	a0,800052ce <create+0x94>
    iunlockput(dp);
    80005280:	854a                	mv	a0,s2
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	8e0080e7          	jalr	-1824(ra) # 80003b62 <iunlockput>
    ilock(ip);
    8000528a:	8526                	mv	a0,s1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	65e080e7          	jalr	1630(ra) # 800038ea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005294:	2981                	sext.w	s3,s3
    80005296:	4789                	li	a5,2
    80005298:	02f99463          	bne	s3,a5,800052c0 <create+0x86>
    8000529c:	0444d783          	lhu	a5,68(s1)
    800052a0:	37f9                	addiw	a5,a5,-2
    800052a2:	17c2                	slli	a5,a5,0x30
    800052a4:	93c1                	srli	a5,a5,0x30
    800052a6:	4705                	li	a4,1
    800052a8:	00f76c63          	bltu	a4,a5,800052c0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052ac:	8526                	mv	a0,s1
    800052ae:	60a6                	ld	ra,72(sp)
    800052b0:	6406                	ld	s0,64(sp)
    800052b2:	74e2                	ld	s1,56(sp)
    800052b4:	7942                	ld	s2,48(sp)
    800052b6:	79a2                	ld	s3,40(sp)
    800052b8:	7a02                	ld	s4,32(sp)
    800052ba:	6ae2                	ld	s5,24(sp)
    800052bc:	6161                	addi	sp,sp,80
    800052be:	8082                	ret
    iunlockput(ip);
    800052c0:	8526                	mv	a0,s1
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	8a0080e7          	jalr	-1888(ra) # 80003b62 <iunlockput>
    return 0;
    800052ca:	4481                	li	s1,0
    800052cc:	b7c5                	j	800052ac <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ce:	85ce                	mv	a1,s3
    800052d0:	00092503          	lw	a0,0(s2)
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	47e080e7          	jalr	1150(ra) # 80003752 <ialloc>
    800052dc:	84aa                	mv	s1,a0
    800052de:	c529                	beqz	a0,80005328 <create+0xee>
  ilock(ip);
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	60a080e7          	jalr	1546(ra) # 800038ea <ilock>
  ip->major = major;
    800052e8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052ec:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052f0:	4785                	li	a5,1
    800052f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052f6:	8526                	mv	a0,s1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	528080e7          	jalr	1320(ra) # 80003820 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005300:	2981                	sext.w	s3,s3
    80005302:	4785                	li	a5,1
    80005304:	02f98a63          	beq	s3,a5,80005338 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005308:	40d0                	lw	a2,4(s1)
    8000530a:	fb040593          	addi	a1,s0,-80
    8000530e:	854a                	mv	a0,s2
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	ce4080e7          	jalr	-796(ra) # 80003ff4 <dirlink>
    80005318:	06054b63          	bltz	a0,8000538e <create+0x154>
  iunlockput(dp);
    8000531c:	854a                	mv	a0,s2
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	844080e7          	jalr	-1980(ra) # 80003b62 <iunlockput>
  return ip;
    80005326:	b759                	j	800052ac <create+0x72>
    panic("create: ialloc");
    80005328:	00003517          	auipc	a0,0x3
    8000532c:	41850513          	addi	a0,a0,1048 # 80008740 <syscalls+0x2c0>
    80005330:	ffffb097          	auipc	ra,0xffffb
    80005334:	200080e7          	jalr	512(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005338:	04a95783          	lhu	a5,74(s2)
    8000533c:	2785                	addiw	a5,a5,1
    8000533e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005342:	854a                	mv	a0,s2
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	4dc080e7          	jalr	1244(ra) # 80003820 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000534c:	40d0                	lw	a2,4(s1)
    8000534e:	00003597          	auipc	a1,0x3
    80005352:	40258593          	addi	a1,a1,1026 # 80008750 <syscalls+0x2d0>
    80005356:	8526                	mv	a0,s1
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	c9c080e7          	jalr	-868(ra) # 80003ff4 <dirlink>
    80005360:	00054f63          	bltz	a0,8000537e <create+0x144>
    80005364:	00492603          	lw	a2,4(s2)
    80005368:	00003597          	auipc	a1,0x3
    8000536c:	e6858593          	addi	a1,a1,-408 # 800081d0 <digits+0x190>
    80005370:	8526                	mv	a0,s1
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	c82080e7          	jalr	-894(ra) # 80003ff4 <dirlink>
    8000537a:	f80557e3          	bgez	a0,80005308 <create+0xce>
      panic("create dots");
    8000537e:	00003517          	auipc	a0,0x3
    80005382:	3da50513          	addi	a0,a0,986 # 80008758 <syscalls+0x2d8>
    80005386:	ffffb097          	auipc	ra,0xffffb
    8000538a:	1aa080e7          	jalr	426(ra) # 80000530 <panic>
    panic("create: dirlink");
    8000538e:	00003517          	auipc	a0,0x3
    80005392:	3da50513          	addi	a0,a0,986 # 80008768 <syscalls+0x2e8>
    80005396:	ffffb097          	auipc	ra,0xffffb
    8000539a:	19a080e7          	jalr	410(ra) # 80000530 <panic>
    return 0;
    8000539e:	84aa                	mv	s1,a0
    800053a0:	b731                	j	800052ac <create+0x72>

00000000800053a2 <sys_dup>:
{
    800053a2:	7179                	addi	sp,sp,-48
    800053a4:	f406                	sd	ra,40(sp)
    800053a6:	f022                	sd	s0,32(sp)
    800053a8:	ec26                	sd	s1,24(sp)
    800053aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053ac:	fd840613          	addi	a2,s0,-40
    800053b0:	4581                	li	a1,0
    800053b2:	4501                	li	a0,0
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	ddc080e7          	jalr	-548(ra) # 80005190 <argfd>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053be:	02054363          	bltz	a0,800053e4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053c2:	fd843503          	ld	a0,-40(s0)
    800053c6:	00000097          	auipc	ra,0x0
    800053ca:	e32080e7          	jalr	-462(ra) # 800051f8 <fdalloc>
    800053ce:	84aa                	mv	s1,a0
    return -1;
    800053d0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053d2:	00054963          	bltz	a0,800053e4 <sys_dup+0x42>
  filedup(f);
    800053d6:	fd843503          	ld	a0,-40(s0)
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	37a080e7          	jalr	890(ra) # 80004754 <filedup>
  return fd;
    800053e2:	87a6                	mv	a5,s1
}
    800053e4:	853e                	mv	a0,a5
    800053e6:	70a2                	ld	ra,40(sp)
    800053e8:	7402                	ld	s0,32(sp)
    800053ea:	64e2                	ld	s1,24(sp)
    800053ec:	6145                	addi	sp,sp,48
    800053ee:	8082                	ret

00000000800053f0 <sys_read>:
{
    800053f0:	7179                	addi	sp,sp,-48
    800053f2:	f406                	sd	ra,40(sp)
    800053f4:	f022                	sd	s0,32(sp)
    800053f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f8:	fe840613          	addi	a2,s0,-24
    800053fc:	4581                	li	a1,0
    800053fe:	4501                	li	a0,0
    80005400:	00000097          	auipc	ra,0x0
    80005404:	d90080e7          	jalr	-624(ra) # 80005190 <argfd>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540a:	04054163          	bltz	a0,8000544c <sys_read+0x5c>
    8000540e:	fe440593          	addi	a1,s0,-28
    80005412:	4509                	li	a0,2
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	964080e7          	jalr	-1692(ra) # 80002d78 <argint>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541e:	02054763          	bltz	a0,8000544c <sys_read+0x5c>
    80005422:	fd840593          	addi	a1,s0,-40
    80005426:	4505                	li	a0,1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	972080e7          	jalr	-1678(ra) # 80002d9a <argaddr>
    return -1;
    80005430:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005432:	00054d63          	bltz	a0,8000544c <sys_read+0x5c>
  return fileread(f, p, n);
    80005436:	fe442603          	lw	a2,-28(s0)
    8000543a:	fd843583          	ld	a1,-40(s0)
    8000543e:	fe843503          	ld	a0,-24(s0)
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	49e080e7          	jalr	1182(ra) # 800048e0 <fileread>
    8000544a:	87aa                	mv	a5,a0
}
    8000544c:	853e                	mv	a0,a5
    8000544e:	70a2                	ld	ra,40(sp)
    80005450:	7402                	ld	s0,32(sp)
    80005452:	6145                	addi	sp,sp,48
    80005454:	8082                	ret

0000000080005456 <sys_write>:
{
    80005456:	7179                	addi	sp,sp,-48
    80005458:	f406                	sd	ra,40(sp)
    8000545a:	f022                	sd	s0,32(sp)
    8000545c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545e:	fe840613          	addi	a2,s0,-24
    80005462:	4581                	li	a1,0
    80005464:	4501                	li	a0,0
    80005466:	00000097          	auipc	ra,0x0
    8000546a:	d2a080e7          	jalr	-726(ra) # 80005190 <argfd>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005470:	04054163          	bltz	a0,800054b2 <sys_write+0x5c>
    80005474:	fe440593          	addi	a1,s0,-28
    80005478:	4509                	li	a0,2
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	8fe080e7          	jalr	-1794(ra) # 80002d78 <argint>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005484:	02054763          	bltz	a0,800054b2 <sys_write+0x5c>
    80005488:	fd840593          	addi	a1,s0,-40
    8000548c:	4505                	li	a0,1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	90c080e7          	jalr	-1780(ra) # 80002d9a <argaddr>
    return -1;
    80005496:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005498:	00054d63          	bltz	a0,800054b2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000549c:	fe442603          	lw	a2,-28(s0)
    800054a0:	fd843583          	ld	a1,-40(s0)
    800054a4:	fe843503          	ld	a0,-24(s0)
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	4fa080e7          	jalr	1274(ra) # 800049a2 <filewrite>
    800054b0:	87aa                	mv	a5,a0
}
    800054b2:	853e                	mv	a0,a5
    800054b4:	70a2                	ld	ra,40(sp)
    800054b6:	7402                	ld	s0,32(sp)
    800054b8:	6145                	addi	sp,sp,48
    800054ba:	8082                	ret

00000000800054bc <sys_close>:
{
    800054bc:	1101                	addi	sp,sp,-32
    800054be:	ec06                	sd	ra,24(sp)
    800054c0:	e822                	sd	s0,16(sp)
    800054c2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054c4:	fe040613          	addi	a2,s0,-32
    800054c8:	fec40593          	addi	a1,s0,-20
    800054cc:	4501                	li	a0,0
    800054ce:	00000097          	auipc	ra,0x0
    800054d2:	cc2080e7          	jalr	-830(ra) # 80005190 <argfd>
    return -1;
    800054d6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054d8:	02054463          	bltz	a0,80005500 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	5aa080e7          	jalr	1450(ra) # 80001a86 <myproc>
    800054e4:	fec42783          	lw	a5,-20(s0)
    800054e8:	07e9                	addi	a5,a5,26
    800054ea:	078e                	slli	a5,a5,0x3
    800054ec:	97aa                	add	a5,a5,a0
    800054ee:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054f2:	fe043503          	ld	a0,-32(s0)
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	2b0080e7          	jalr	688(ra) # 800047a6 <fileclose>
  return 0;
    800054fe:	4781                	li	a5,0
}
    80005500:	853e                	mv	a0,a5
    80005502:	60e2                	ld	ra,24(sp)
    80005504:	6442                	ld	s0,16(sp)
    80005506:	6105                	addi	sp,sp,32
    80005508:	8082                	ret

000000008000550a <sys_fstat>:
{
    8000550a:	1101                	addi	sp,sp,-32
    8000550c:	ec06                	sd	ra,24(sp)
    8000550e:	e822                	sd	s0,16(sp)
    80005510:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005512:	fe840613          	addi	a2,s0,-24
    80005516:	4581                	li	a1,0
    80005518:	4501                	li	a0,0
    8000551a:	00000097          	auipc	ra,0x0
    8000551e:	c76080e7          	jalr	-906(ra) # 80005190 <argfd>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005524:	02054563          	bltz	a0,8000554e <sys_fstat+0x44>
    80005528:	fe040593          	addi	a1,s0,-32
    8000552c:	4505                	li	a0,1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	86c080e7          	jalr	-1940(ra) # 80002d9a <argaddr>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005538:	00054b63          	bltz	a0,8000554e <sys_fstat+0x44>
  return filestat(f, st);
    8000553c:	fe043583          	ld	a1,-32(s0)
    80005540:	fe843503          	ld	a0,-24(s0)
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	32a080e7          	jalr	810(ra) # 8000486e <filestat>
    8000554c:	87aa                	mv	a5,a0
}
    8000554e:	853e                	mv	a0,a5
    80005550:	60e2                	ld	ra,24(sp)
    80005552:	6442                	ld	s0,16(sp)
    80005554:	6105                	addi	sp,sp,32
    80005556:	8082                	ret

0000000080005558 <sys_link>:
{
    80005558:	7169                	addi	sp,sp,-304
    8000555a:	f606                	sd	ra,296(sp)
    8000555c:	f222                	sd	s0,288(sp)
    8000555e:	ee26                	sd	s1,280(sp)
    80005560:	ea4a                	sd	s2,272(sp)
    80005562:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005564:	08000613          	li	a2,128
    80005568:	ed040593          	addi	a1,s0,-304
    8000556c:	4501                	li	a0,0
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	84e080e7          	jalr	-1970(ra) # 80002dbc <argstr>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005578:	10054e63          	bltz	a0,80005694 <sys_link+0x13c>
    8000557c:	08000613          	li	a2,128
    80005580:	f5040593          	addi	a1,s0,-176
    80005584:	4505                	li	a0,1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	836080e7          	jalr	-1994(ra) # 80002dbc <argstr>
    return -1;
    8000558e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005590:	10054263          	bltz	a0,80005694 <sys_link+0x13c>
  begin_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	d3e080e7          	jalr	-706(ra) # 800042d2 <begin_op>
  if((ip = namei(old)) == 0){
    8000559c:	ed040513          	addi	a0,s0,-304
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	b16080e7          	jalr	-1258(ra) # 800040b6 <namei>
    800055a8:	84aa                	mv	s1,a0
    800055aa:	c551                	beqz	a0,80005636 <sys_link+0xde>
  ilock(ip);
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	33e080e7          	jalr	830(ra) # 800038ea <ilock>
  if(ip->type == T_DIR){
    800055b4:	04449703          	lh	a4,68(s1)
    800055b8:	4785                	li	a5,1
    800055ba:	08f70463          	beq	a4,a5,80005642 <sys_link+0xea>
  ip->nlink++;
    800055be:	04a4d783          	lhu	a5,74(s1)
    800055c2:	2785                	addiw	a5,a5,1
    800055c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	256080e7          	jalr	598(ra) # 80003820 <iupdate>
  iunlock(ip);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	3ee080e7          	jalr	1006(ra) # 800039c2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055dc:	fd040593          	addi	a1,s0,-48
    800055e0:	f5040513          	addi	a0,s0,-176
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	af0080e7          	jalr	-1296(ra) # 800040d4 <nameiparent>
    800055ec:	892a                	mv	s2,a0
    800055ee:	c935                	beqz	a0,80005662 <sys_link+0x10a>
  ilock(dp);
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	2fa080e7          	jalr	762(ra) # 800038ea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055f8:	00092703          	lw	a4,0(s2)
    800055fc:	409c                	lw	a5,0(s1)
    800055fe:	04f71d63          	bne	a4,a5,80005658 <sys_link+0x100>
    80005602:	40d0                	lw	a2,4(s1)
    80005604:	fd040593          	addi	a1,s0,-48
    80005608:	854a                	mv	a0,s2
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	9ea080e7          	jalr	-1558(ra) # 80003ff4 <dirlink>
    80005612:	04054363          	bltz	a0,80005658 <sys_link+0x100>
  iunlockput(dp);
    80005616:	854a                	mv	a0,s2
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	54a080e7          	jalr	1354(ra) # 80003b62 <iunlockput>
  iput(ip);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	498080e7          	jalr	1176(ra) # 80003aba <iput>
  end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	d28080e7          	jalr	-728(ra) # 80004352 <end_op>
  return 0;
    80005632:	4781                	li	a5,0
    80005634:	a085                	j	80005694 <sys_link+0x13c>
    end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	d1c080e7          	jalr	-740(ra) # 80004352 <end_op>
    return -1;
    8000563e:	57fd                	li	a5,-1
    80005640:	a891                	j	80005694 <sys_link+0x13c>
    iunlockput(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	51e080e7          	jalr	1310(ra) # 80003b62 <iunlockput>
    end_op();
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	d06080e7          	jalr	-762(ra) # 80004352 <end_op>
    return -1;
    80005654:	57fd                	li	a5,-1
    80005656:	a83d                	j	80005694 <sys_link+0x13c>
    iunlockput(dp);
    80005658:	854a                	mv	a0,s2
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	508080e7          	jalr	1288(ra) # 80003b62 <iunlockput>
  ilock(ip);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	286080e7          	jalr	646(ra) # 800038ea <ilock>
  ip->nlink--;
    8000566c:	04a4d783          	lhu	a5,74(s1)
    80005670:	37fd                	addiw	a5,a5,-1
    80005672:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	1a8080e7          	jalr	424(ra) # 80003820 <iupdate>
  iunlockput(ip);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	4e0080e7          	jalr	1248(ra) # 80003b62 <iunlockput>
  end_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	cc8080e7          	jalr	-824(ra) # 80004352 <end_op>
  return -1;
    80005692:	57fd                	li	a5,-1
}
    80005694:	853e                	mv	a0,a5
    80005696:	70b2                	ld	ra,296(sp)
    80005698:	7412                	ld	s0,288(sp)
    8000569a:	64f2                	ld	s1,280(sp)
    8000569c:	6952                	ld	s2,272(sp)
    8000569e:	6155                	addi	sp,sp,304
    800056a0:	8082                	ret

00000000800056a2 <sys_unlink>:
{
    800056a2:	7151                	addi	sp,sp,-240
    800056a4:	f586                	sd	ra,232(sp)
    800056a6:	f1a2                	sd	s0,224(sp)
    800056a8:	eda6                	sd	s1,216(sp)
    800056aa:	e9ca                	sd	s2,208(sp)
    800056ac:	e5ce                	sd	s3,200(sp)
    800056ae:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056b0:	08000613          	li	a2,128
    800056b4:	f3040593          	addi	a1,s0,-208
    800056b8:	4501                	li	a0,0
    800056ba:	ffffd097          	auipc	ra,0xffffd
    800056be:	702080e7          	jalr	1794(ra) # 80002dbc <argstr>
    800056c2:	18054163          	bltz	a0,80005844 <sys_unlink+0x1a2>
  begin_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	c0c080e7          	jalr	-1012(ra) # 800042d2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ce:	fb040593          	addi	a1,s0,-80
    800056d2:	f3040513          	addi	a0,s0,-208
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	9fe080e7          	jalr	-1538(ra) # 800040d4 <nameiparent>
    800056de:	84aa                	mv	s1,a0
    800056e0:	c979                	beqz	a0,800057b6 <sys_unlink+0x114>
  ilock(dp);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	208080e7          	jalr	520(ra) # 800038ea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056ea:	00003597          	auipc	a1,0x3
    800056ee:	06658593          	addi	a1,a1,102 # 80008750 <syscalls+0x2d0>
    800056f2:	fb040513          	addi	a0,s0,-80
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	6d4080e7          	jalr	1748(ra) # 80003dca <namecmp>
    800056fe:	14050a63          	beqz	a0,80005852 <sys_unlink+0x1b0>
    80005702:	00003597          	auipc	a1,0x3
    80005706:	ace58593          	addi	a1,a1,-1330 # 800081d0 <digits+0x190>
    8000570a:	fb040513          	addi	a0,s0,-80
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	6bc080e7          	jalr	1724(ra) # 80003dca <namecmp>
    80005716:	12050e63          	beqz	a0,80005852 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000571a:	f2c40613          	addi	a2,s0,-212
    8000571e:	fb040593          	addi	a1,s0,-80
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	6c0080e7          	jalr	1728(ra) # 80003de4 <dirlookup>
    8000572c:	892a                	mv	s2,a0
    8000572e:	12050263          	beqz	a0,80005852 <sys_unlink+0x1b0>
  ilock(ip);
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	1b8080e7          	jalr	440(ra) # 800038ea <ilock>
  if(ip->nlink < 1)
    8000573a:	04a91783          	lh	a5,74(s2)
    8000573e:	08f05263          	blez	a5,800057c2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005742:	04491703          	lh	a4,68(s2)
    80005746:	4785                	li	a5,1
    80005748:	08f70563          	beq	a4,a5,800057d2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000574c:	4641                	li	a2,16
    8000574e:	4581                	li	a1,0
    80005750:	fc040513          	addi	a0,s0,-64
    80005754:	ffffb097          	auipc	ra,0xffffb
    80005758:	57e080e7          	jalr	1406(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000575c:	4741                	li	a4,16
    8000575e:	f2c42683          	lw	a3,-212(s0)
    80005762:	fc040613          	addi	a2,s0,-64
    80005766:	4581                	li	a1,0
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	542080e7          	jalr	1346(ra) # 80003cac <writei>
    80005772:	47c1                	li	a5,16
    80005774:	0af51563          	bne	a0,a5,8000581e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005778:	04491703          	lh	a4,68(s2)
    8000577c:	4785                	li	a5,1
    8000577e:	0af70863          	beq	a4,a5,8000582e <sys_unlink+0x18c>
  iunlockput(dp);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	3de080e7          	jalr	990(ra) # 80003b62 <iunlockput>
  ip->nlink--;
    8000578c:	04a95783          	lhu	a5,74(s2)
    80005790:	37fd                	addiw	a5,a5,-1
    80005792:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005796:	854a                	mv	a0,s2
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	088080e7          	jalr	136(ra) # 80003820 <iupdate>
  iunlockput(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	3c0080e7          	jalr	960(ra) # 80003b62 <iunlockput>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	ba8080e7          	jalr	-1112(ra) # 80004352 <end_op>
  return 0;
    800057b2:	4501                	li	a0,0
    800057b4:	a84d                	j	80005866 <sys_unlink+0x1c4>
    end_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	b9c080e7          	jalr	-1124(ra) # 80004352 <end_op>
    return -1;
    800057be:	557d                	li	a0,-1
    800057c0:	a05d                	j	80005866 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057c2:	00003517          	auipc	a0,0x3
    800057c6:	fb650513          	addi	a0,a0,-74 # 80008778 <syscalls+0x2f8>
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	d66080e7          	jalr	-666(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d2:	04c92703          	lw	a4,76(s2)
    800057d6:	02000793          	li	a5,32
    800057da:	f6e7f9e3          	bgeu	a5,a4,8000574c <sys_unlink+0xaa>
    800057de:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e2:	4741                	li	a4,16
    800057e4:	86ce                	mv	a3,s3
    800057e6:	f1840613          	addi	a2,s0,-232
    800057ea:	4581                	li	a1,0
    800057ec:	854a                	mv	a0,s2
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	3c6080e7          	jalr	966(ra) # 80003bb4 <readi>
    800057f6:	47c1                	li	a5,16
    800057f8:	00f51b63          	bne	a0,a5,8000580e <sys_unlink+0x16c>
    if(de.inum != 0)
    800057fc:	f1845783          	lhu	a5,-232(s0)
    80005800:	e7a1                	bnez	a5,80005848 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005802:	29c1                	addiw	s3,s3,16
    80005804:	04c92783          	lw	a5,76(s2)
    80005808:	fcf9ede3          	bltu	s3,a5,800057e2 <sys_unlink+0x140>
    8000580c:	b781                	j	8000574c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000580e:	00003517          	auipc	a0,0x3
    80005812:	f8250513          	addi	a0,a0,-126 # 80008790 <syscalls+0x310>
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	d1a080e7          	jalr	-742(ra) # 80000530 <panic>
    panic("unlink: writei");
    8000581e:	00003517          	auipc	a0,0x3
    80005822:	f8a50513          	addi	a0,a0,-118 # 800087a8 <syscalls+0x328>
    80005826:	ffffb097          	auipc	ra,0xffffb
    8000582a:	d0a080e7          	jalr	-758(ra) # 80000530 <panic>
    dp->nlink--;
    8000582e:	04a4d783          	lhu	a5,74(s1)
    80005832:	37fd                	addiw	a5,a5,-1
    80005834:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	fe6080e7          	jalr	-26(ra) # 80003820 <iupdate>
    80005842:	b781                	j	80005782 <sys_unlink+0xe0>
    return -1;
    80005844:	557d                	li	a0,-1
    80005846:	a005                	j	80005866 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	318080e7          	jalr	792(ra) # 80003b62 <iunlockput>
  iunlockput(dp);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	30e080e7          	jalr	782(ra) # 80003b62 <iunlockput>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	af6080e7          	jalr	-1290(ra) # 80004352 <end_op>
  return -1;
    80005864:	557d                	li	a0,-1
}
    80005866:	70ae                	ld	ra,232(sp)
    80005868:	740e                	ld	s0,224(sp)
    8000586a:	64ee                	ld	s1,216(sp)
    8000586c:	694e                	ld	s2,208(sp)
    8000586e:	69ae                	ld	s3,200(sp)
    80005870:	616d                	addi	sp,sp,240
    80005872:	8082                	ret

0000000080005874 <sys_open>:

uint64
sys_open(void)
{
    80005874:	7131                	addi	sp,sp,-192
    80005876:	fd06                	sd	ra,184(sp)
    80005878:	f922                	sd	s0,176(sp)
    8000587a:	f526                	sd	s1,168(sp)
    8000587c:	f14a                	sd	s2,160(sp)
    8000587e:	ed4e                	sd	s3,152(sp)
    80005880:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005882:	08000613          	li	a2,128
    80005886:	f5040593          	addi	a1,s0,-176
    8000588a:	4501                	li	a0,0
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	530080e7          	jalr	1328(ra) # 80002dbc <argstr>
    return -1;
    80005894:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005896:	0c054163          	bltz	a0,80005958 <sys_open+0xe4>
    8000589a:	f4c40593          	addi	a1,s0,-180
    8000589e:	4505                	li	a0,1
    800058a0:	ffffd097          	auipc	ra,0xffffd
    800058a4:	4d8080e7          	jalr	1240(ra) # 80002d78 <argint>
    800058a8:	0a054863          	bltz	a0,80005958 <sys_open+0xe4>

  begin_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	a26080e7          	jalr	-1498(ra) # 800042d2 <begin_op>

  if(omode & O_CREATE){
    800058b4:	f4c42783          	lw	a5,-180(s0)
    800058b8:	2007f793          	andi	a5,a5,512
    800058bc:	cbdd                	beqz	a5,80005972 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058be:	4681                	li	a3,0
    800058c0:	4601                	li	a2,0
    800058c2:	4589                	li	a1,2
    800058c4:	f5040513          	addi	a0,s0,-176
    800058c8:	00000097          	auipc	ra,0x0
    800058cc:	972080e7          	jalr	-1678(ra) # 8000523a <create>
    800058d0:	892a                	mv	s2,a0
    if(ip == 0){
    800058d2:	c959                	beqz	a0,80005968 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058d4:	04491703          	lh	a4,68(s2)
    800058d8:	478d                	li	a5,3
    800058da:	00f71763          	bne	a4,a5,800058e8 <sys_open+0x74>
    800058de:	04695703          	lhu	a4,70(s2)
    800058e2:	47a5                	li	a5,9
    800058e4:	0ce7ec63          	bltu	a5,a4,800059bc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	e02080e7          	jalr	-510(ra) # 800046ea <filealloc>
    800058f0:	89aa                	mv	s3,a0
    800058f2:	10050263          	beqz	a0,800059f6 <sys_open+0x182>
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	902080e7          	jalr	-1790(ra) # 800051f8 <fdalloc>
    800058fe:	84aa                	mv	s1,a0
    80005900:	0e054663          	bltz	a0,800059ec <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	478d                	li	a5,3
    8000590a:	0cf70463          	beq	a4,a5,800059d2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000590e:	4789                	li	a5,2
    80005910:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005914:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005918:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000591c:	f4c42783          	lw	a5,-180(s0)
    80005920:	0017c713          	xori	a4,a5,1
    80005924:	8b05                	andi	a4,a4,1
    80005926:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000592a:	0037f713          	andi	a4,a5,3
    8000592e:	00e03733          	snez	a4,a4
    80005932:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005936:	4007f793          	andi	a5,a5,1024
    8000593a:	c791                	beqz	a5,80005946 <sys_open+0xd2>
    8000593c:	04491703          	lh	a4,68(s2)
    80005940:	4789                	li	a5,2
    80005942:	08f70f63          	beq	a4,a5,800059e0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005946:	854a                	mv	a0,s2
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	07a080e7          	jalr	122(ra) # 800039c2 <iunlock>
  end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	a02080e7          	jalr	-1534(ra) # 80004352 <end_op>

  return fd;
}
    80005958:	8526                	mv	a0,s1
    8000595a:	70ea                	ld	ra,184(sp)
    8000595c:	744a                	ld	s0,176(sp)
    8000595e:	74aa                	ld	s1,168(sp)
    80005960:	790a                	ld	s2,160(sp)
    80005962:	69ea                	ld	s3,152(sp)
    80005964:	6129                	addi	sp,sp,192
    80005966:	8082                	ret
      end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	9ea080e7          	jalr	-1558(ra) # 80004352 <end_op>
      return -1;
    80005970:	b7e5                	j	80005958 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005972:	f5040513          	addi	a0,s0,-176
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	740080e7          	jalr	1856(ra) # 800040b6 <namei>
    8000597e:	892a                	mv	s2,a0
    80005980:	c905                	beqz	a0,800059b0 <sys_open+0x13c>
    ilock(ip);
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	f68080e7          	jalr	-152(ra) # 800038ea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	4785                	li	a5,1
    80005990:	f4f712e3          	bne	a4,a5,800058d4 <sys_open+0x60>
    80005994:	f4c42783          	lw	a5,-180(s0)
    80005998:	dba1                	beqz	a5,800058e8 <sys_open+0x74>
      iunlockput(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	1c6080e7          	jalr	454(ra) # 80003b62 <iunlockput>
      end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	9ae080e7          	jalr	-1618(ra) # 80004352 <end_op>
      return -1;
    800059ac:	54fd                	li	s1,-1
    800059ae:	b76d                	j	80005958 <sys_open+0xe4>
      end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	9a2080e7          	jalr	-1630(ra) # 80004352 <end_op>
      return -1;
    800059b8:	54fd                	li	s1,-1
    800059ba:	bf79                	j	80005958 <sys_open+0xe4>
    iunlockput(ip);
    800059bc:	854a                	mv	a0,s2
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	1a4080e7          	jalr	420(ra) # 80003b62 <iunlockput>
    end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	98c080e7          	jalr	-1652(ra) # 80004352 <end_op>
    return -1;
    800059ce:	54fd                	li	s1,-1
    800059d0:	b761                	j	80005958 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059d2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059d6:	04691783          	lh	a5,70(s2)
    800059da:	02f99223          	sh	a5,36(s3)
    800059de:	bf2d                	j	80005918 <sys_open+0xa4>
    itrunc(ip);
    800059e0:	854a                	mv	a0,s2
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	02c080e7          	jalr	44(ra) # 80003a0e <itrunc>
    800059ea:	bfb1                	j	80005946 <sys_open+0xd2>
      fileclose(f);
    800059ec:	854e                	mv	a0,s3
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	db8080e7          	jalr	-584(ra) # 800047a6 <fileclose>
    iunlockput(ip);
    800059f6:	854a                	mv	a0,s2
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	16a080e7          	jalr	362(ra) # 80003b62 <iunlockput>
    end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	952080e7          	jalr	-1710(ra) # 80004352 <end_op>
    return -1;
    80005a08:	54fd                	li	s1,-1
    80005a0a:	b7b9                	j	80005958 <sys_open+0xe4>

0000000080005a0c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a0c:	7175                	addi	sp,sp,-144
    80005a0e:	e506                	sd	ra,136(sp)
    80005a10:	e122                	sd	s0,128(sp)
    80005a12:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	8be080e7          	jalr	-1858(ra) # 800042d2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a1c:	08000613          	li	a2,128
    80005a20:	f7040593          	addi	a1,s0,-144
    80005a24:	4501                	li	a0,0
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	396080e7          	jalr	918(ra) # 80002dbc <argstr>
    80005a2e:	02054963          	bltz	a0,80005a60 <sys_mkdir+0x54>
    80005a32:	4681                	li	a3,0
    80005a34:	4601                	li	a2,0
    80005a36:	4585                	li	a1,1
    80005a38:	f7040513          	addi	a0,s0,-144
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	7fe080e7          	jalr	2046(ra) # 8000523a <create>
    80005a44:	cd11                	beqz	a0,80005a60 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	11c080e7          	jalr	284(ra) # 80003b62 <iunlockput>
  end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	904080e7          	jalr	-1788(ra) # 80004352 <end_op>
  return 0;
    80005a56:	4501                	li	a0,0
}
    80005a58:	60aa                	ld	ra,136(sp)
    80005a5a:	640a                	ld	s0,128(sp)
    80005a5c:	6149                	addi	sp,sp,144
    80005a5e:	8082                	ret
    end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	8f2080e7          	jalr	-1806(ra) # 80004352 <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	b7fd                	j	80005a58 <sys_mkdir+0x4c>

0000000080005a6c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a6c:	7135                	addi	sp,sp,-160
    80005a6e:	ed06                	sd	ra,152(sp)
    80005a70:	e922                	sd	s0,144(sp)
    80005a72:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	85e080e7          	jalr	-1954(ra) # 800042d2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7c:	08000613          	li	a2,128
    80005a80:	f7040593          	addi	a1,s0,-144
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	336080e7          	jalr	822(ra) # 80002dbc <argstr>
    80005a8e:	04054a63          	bltz	a0,80005ae2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a92:	f6c40593          	addi	a1,s0,-148
    80005a96:	4505                	li	a0,1
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	2e0080e7          	jalr	736(ra) # 80002d78 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa0:	04054163          	bltz	a0,80005ae2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005aa4:	f6840593          	addi	a1,s0,-152
    80005aa8:	4509                	li	a0,2
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	2ce080e7          	jalr	718(ra) # 80002d78 <argint>
     argint(1, &major) < 0 ||
    80005ab2:	02054863          	bltz	a0,80005ae2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab6:	f6841683          	lh	a3,-152(s0)
    80005aba:	f6c41603          	lh	a2,-148(s0)
    80005abe:	458d                	li	a1,3
    80005ac0:	f7040513          	addi	a0,s0,-144
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	776080e7          	jalr	1910(ra) # 8000523a <create>
     argint(2, &minor) < 0 ||
    80005acc:	c919                	beqz	a0,80005ae2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	094080e7          	jalr	148(ra) # 80003b62 <iunlockput>
  end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	87c080e7          	jalr	-1924(ra) # 80004352 <end_op>
  return 0;
    80005ade:	4501                	li	a0,0
    80005ae0:	a031                	j	80005aec <sys_mknod+0x80>
    end_op();
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	870080e7          	jalr	-1936(ra) # 80004352 <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
}
    80005aec:	60ea                	ld	ra,152(sp)
    80005aee:	644a                	ld	s0,144(sp)
    80005af0:	610d                	addi	sp,sp,160
    80005af2:	8082                	ret

0000000080005af4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af4:	7135                	addi	sp,sp,-160
    80005af6:	ed06                	sd	ra,152(sp)
    80005af8:	e922                	sd	s0,144(sp)
    80005afa:	e526                	sd	s1,136(sp)
    80005afc:	e14a                	sd	s2,128(sp)
    80005afe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b00:	ffffc097          	auipc	ra,0xffffc
    80005b04:	f86080e7          	jalr	-122(ra) # 80001a86 <myproc>
    80005b08:	892a                	mv	s2,a0
  
  begin_op();
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	7c8080e7          	jalr	1992(ra) # 800042d2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b12:	08000613          	li	a2,128
    80005b16:	f6040593          	addi	a1,s0,-160
    80005b1a:	4501                	li	a0,0
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	2a0080e7          	jalr	672(ra) # 80002dbc <argstr>
    80005b24:	04054b63          	bltz	a0,80005b7a <sys_chdir+0x86>
    80005b28:	f6040513          	addi	a0,s0,-160
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	58a080e7          	jalr	1418(ra) # 800040b6 <namei>
    80005b34:	84aa                	mv	s1,a0
    80005b36:	c131                	beqz	a0,80005b7a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	db2080e7          	jalr	-590(ra) # 800038ea <ilock>
  if(ip->type != T_DIR){
    80005b40:	04449703          	lh	a4,68(s1)
    80005b44:	4785                	li	a5,1
    80005b46:	04f71063          	bne	a4,a5,80005b86 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	e76080e7          	jalr	-394(ra) # 800039c2 <iunlock>
  iput(p->cwd);
    80005b54:	15093503          	ld	a0,336(s2)
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	f62080e7          	jalr	-158(ra) # 80003aba <iput>
  end_op();
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	7f2080e7          	jalr	2034(ra) # 80004352 <end_op>
  p->cwd = ip;
    80005b68:	14993823          	sd	s1,336(s2)
  return 0;
    80005b6c:	4501                	li	a0,0
}
    80005b6e:	60ea                	ld	ra,152(sp)
    80005b70:	644a                	ld	s0,144(sp)
    80005b72:	64aa                	ld	s1,136(sp)
    80005b74:	690a                	ld	s2,128(sp)
    80005b76:	610d                	addi	sp,sp,160
    80005b78:	8082                	ret
    end_op();
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	7d8080e7          	jalr	2008(ra) # 80004352 <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	b7ed                	j	80005b6e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	fda080e7          	jalr	-38(ra) # 80003b62 <iunlockput>
    end_op();
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	7c2080e7          	jalr	1986(ra) # 80004352 <end_op>
    return -1;
    80005b98:	557d                	li	a0,-1
    80005b9a:	bfd1                	j	80005b6e <sys_chdir+0x7a>

0000000080005b9c <sys_exec>:

uint64
sys_exec(void)
{
    80005b9c:	7145                	addi	sp,sp,-464
    80005b9e:	e786                	sd	ra,456(sp)
    80005ba0:	e3a2                	sd	s0,448(sp)
    80005ba2:	ff26                	sd	s1,440(sp)
    80005ba4:	fb4a                	sd	s2,432(sp)
    80005ba6:	f74e                	sd	s3,424(sp)
    80005ba8:	f352                	sd	s4,416(sp)
    80005baa:	ef56                	sd	s5,408(sp)
    80005bac:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bae:	08000613          	li	a2,128
    80005bb2:	f4040593          	addi	a1,s0,-192
    80005bb6:	4501                	li	a0,0
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	204080e7          	jalr	516(ra) # 80002dbc <argstr>
    return -1;
    80005bc0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bc2:	0c054a63          	bltz	a0,80005c96 <sys_exec+0xfa>
    80005bc6:	e3840593          	addi	a1,s0,-456
    80005bca:	4505                	li	a0,1
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	1ce080e7          	jalr	462(ra) # 80002d9a <argaddr>
    80005bd4:	0c054163          	bltz	a0,80005c96 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bd8:	10000613          	li	a2,256
    80005bdc:	4581                	li	a1,0
    80005bde:	e4040513          	addi	a0,s0,-448
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	0f0080e7          	jalr	240(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bee:	89a6                	mv	s3,s1
    80005bf0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bf2:	02000a13          	li	s4,32
    80005bf6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bfa:	00391513          	slli	a0,s2,0x3
    80005bfe:	e3040593          	addi	a1,s0,-464
    80005c02:	e3843783          	ld	a5,-456(s0)
    80005c06:	953e                	add	a0,a0,a5
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	0d6080e7          	jalr	214(ra) # 80002cde <fetchaddr>
    80005c10:	02054a63          	bltz	a0,80005c44 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c14:	e3043783          	ld	a5,-464(s0)
    80005c18:	c3b9                	beqz	a5,80005c5e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	ecc080e7          	jalr	-308(ra) # 80000ae6 <kalloc>
    80005c22:	85aa                	mv	a1,a0
    80005c24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c28:	cd11                	beqz	a0,80005c44 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c2a:	6605                	lui	a2,0x1
    80005c2c:	e3043503          	ld	a0,-464(s0)
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	100080e7          	jalr	256(ra) # 80002d30 <fetchstr>
    80005c38:	00054663          	bltz	a0,80005c44 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c3c:	0905                	addi	s2,s2,1
    80005c3e:	09a1                	addi	s3,s3,8
    80005c40:	fb491be3          	bne	s2,s4,80005bf6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048913          	addi	s2,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c529                	beqz	a0,80005c94 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	d9e080e7          	jalr	-610(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff2499e3          	bne	s1,s2,80005c48 <sys_exec+0xac>
  return -1;
    80005c5a:	597d                	li	s2,-1
    80005c5c:	a82d                	j	80005c96 <sys_exec+0xfa>
      argv[i] = 0;
    80005c5e:	0a8e                	slli	s5,s5,0x3
    80005c60:	fc040793          	addi	a5,s0,-64
    80005c64:	9abe                	add	s5,s5,a5
    80005c66:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c6a:	e4040593          	addi	a1,s0,-448
    80005c6e:	f4040513          	addi	a0,s0,-192
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	194080e7          	jalr	404(ra) # 80004e06 <exec>
    80005c7a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	10048993          	addi	s3,s1,256
    80005c80:	6088                	ld	a0,0(s1)
    80005c82:	c911                	beqz	a0,80005c96 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	d66080e7          	jalr	-666(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	04a1                	addi	s1,s1,8
    80005c8e:	ff3499e3          	bne	s1,s3,80005c80 <sys_exec+0xe4>
    80005c92:	a011                	j	80005c96 <sys_exec+0xfa>
  return -1;
    80005c94:	597d                	li	s2,-1
}
    80005c96:	854a                	mv	a0,s2
    80005c98:	60be                	ld	ra,456(sp)
    80005c9a:	641e                	ld	s0,448(sp)
    80005c9c:	74fa                	ld	s1,440(sp)
    80005c9e:	795a                	ld	s2,432(sp)
    80005ca0:	79ba                	ld	s3,424(sp)
    80005ca2:	7a1a                	ld	s4,416(sp)
    80005ca4:	6afa                	ld	s5,408(sp)
    80005ca6:	6179                	addi	sp,sp,464
    80005ca8:	8082                	ret

0000000080005caa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005caa:	7139                	addi	sp,sp,-64
    80005cac:	fc06                	sd	ra,56(sp)
    80005cae:	f822                	sd	s0,48(sp)
    80005cb0:	f426                	sd	s1,40(sp)
    80005cb2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cb4:	ffffc097          	auipc	ra,0xffffc
    80005cb8:	dd2080e7          	jalr	-558(ra) # 80001a86 <myproc>
    80005cbc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cbe:	fd840593          	addi	a1,s0,-40
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	0d6080e7          	jalr	214(ra) # 80002d9a <argaddr>
    return -1;
    80005ccc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cce:	0e054063          	bltz	a0,80005dae <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cd2:	fc840593          	addi	a1,s0,-56
    80005cd6:	fd040513          	addi	a0,s0,-48
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	dfc080e7          	jalr	-516(ra) # 80004ad6 <pipealloc>
    return -1;
    80005ce2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ce4:	0c054563          	bltz	a0,80005dae <sys_pipe+0x104>
  fd0 = -1;
    80005ce8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cec:	fd043503          	ld	a0,-48(s0)
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	508080e7          	jalr	1288(ra) # 800051f8 <fdalloc>
    80005cf8:	fca42223          	sw	a0,-60(s0)
    80005cfc:	08054c63          	bltz	a0,80005d94 <sys_pipe+0xea>
    80005d00:	fc843503          	ld	a0,-56(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	4f4080e7          	jalr	1268(ra) # 800051f8 <fdalloc>
    80005d0c:	fca42023          	sw	a0,-64(s0)
    80005d10:	06054863          	bltz	a0,80005d80 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d14:	4691                	li	a3,4
    80005d16:	fc440613          	addi	a2,s0,-60
    80005d1a:	fd843583          	ld	a1,-40(s0)
    80005d1e:	68a8                	ld	a0,80(s1)
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	91c080e7          	jalr	-1764(ra) # 8000163c <copyout>
    80005d28:	02054063          	bltz	a0,80005d48 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d2c:	4691                	li	a3,4
    80005d2e:	fc040613          	addi	a2,s0,-64
    80005d32:	fd843583          	ld	a1,-40(s0)
    80005d36:	0591                	addi	a1,a1,4
    80005d38:	68a8                	ld	a0,80(s1)
    80005d3a:	ffffc097          	auipc	ra,0xffffc
    80005d3e:	902080e7          	jalr	-1790(ra) # 8000163c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d42:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d44:	06055563          	bgez	a0,80005dae <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d48:	fc442783          	lw	a5,-60(s0)
    80005d4c:	07e9                	addi	a5,a5,26
    80005d4e:	078e                	slli	a5,a5,0x3
    80005d50:	97a6                	add	a5,a5,s1
    80005d52:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d56:	fc042503          	lw	a0,-64(s0)
    80005d5a:	0569                	addi	a0,a0,26
    80005d5c:	050e                	slli	a0,a0,0x3
    80005d5e:	9526                	add	a0,a0,s1
    80005d60:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d64:	fd043503          	ld	a0,-48(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	a3e080e7          	jalr	-1474(ra) # 800047a6 <fileclose>
    fileclose(wf);
    80005d70:	fc843503          	ld	a0,-56(s0)
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	a32080e7          	jalr	-1486(ra) # 800047a6 <fileclose>
    return -1;
    80005d7c:	57fd                	li	a5,-1
    80005d7e:	a805                	j	80005dae <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d80:	fc442783          	lw	a5,-60(s0)
    80005d84:	0007c863          	bltz	a5,80005d94 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d88:	01a78513          	addi	a0,a5,26
    80005d8c:	050e                	slli	a0,a0,0x3
    80005d8e:	9526                	add	a0,a0,s1
    80005d90:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d94:	fd043503          	ld	a0,-48(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	a0e080e7          	jalr	-1522(ra) # 800047a6 <fileclose>
    fileclose(wf);
    80005da0:	fc843503          	ld	a0,-56(s0)
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	a02080e7          	jalr	-1534(ra) # 800047a6 <fileclose>
    return -1;
    80005dac:	57fd                	li	a5,-1
}
    80005dae:	853e                	mv	a0,a5
    80005db0:	70e2                	ld	ra,56(sp)
    80005db2:	7442                	ld	s0,48(sp)
    80005db4:	74a2                	ld	s1,40(sp)
    80005db6:	6121                	addi	sp,sp,64
    80005db8:	8082                	ret

0000000080005dba <sys_mmap>:

uint64
sys_mmap(void){
    80005dba:	711d                	addi	sp,sp,-96
    80005dbc:	ec86                	sd	ra,88(sp)
    80005dbe:	e8a2                	sd	s0,80(sp)
    80005dc0:	e4a6                	sd	s1,72(sp)
    80005dc2:	e0ca                	sd	s2,64(sp)
    80005dc4:	fc4e                	sd	s3,56(sp)
    80005dc6:	1080                	addi	s0,sp,96
  int fd; //file descriptor
  int offset;
  struct file *f;
  struct proc *p;

  p = myproc();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	cbe080e7          	jalr	-834(ra) # 80001a86 <myproc>
    80005dd0:	892a                	mv	s2,a0


  //获取参数
  if(argaddr(0,&start_address) < 0){
    80005dd2:	fc840593          	addi	a1,s0,-56
    80005dd6:	4501                	li	a0,0
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	fc2080e7          	jalr	-62(ra) # 80002d9a <argaddr>
    80005de0:	0a054d63          	bltz	a0,80005e9a <sys_mmap+0xe0>
    printf("mmap:get st");
    return -1;
  }
  if(argint(1,&length) < 0){
    80005de4:	fc440593          	addi	a1,s0,-60
    80005de8:	4505                	li	a0,1
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	f8e080e7          	jalr	-114(ra) # 80002d78 <argint>
    80005df2:	0a054e63          	bltz	a0,80005eae <sys_mmap+0xf4>
    printf("mmap:get len");
    return -1;
  }
  if(argint(2,&prot) < 0){
    80005df6:	fc040593          	addi	a1,s0,-64
    80005dfa:	4509                	li	a0,2
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	f7c080e7          	jalr	-132(ra) # 80002d78 <argint>
    80005e04:	0a054f63          	bltz	a0,80005ec2 <sys_mmap+0x108>
    printf("mmap:get prot");
    return -1;
  }
  if(argint(3,&flags) < 0){
    80005e08:	fbc40593          	addi	a1,s0,-68
    80005e0c:	450d                	li	a0,3
    80005e0e:	ffffd097          	auipc	ra,0xffffd
    80005e12:	f6a080e7          	jalr	-150(ra) # 80002d78 <argint>
    80005e16:	0c054063          	bltz	a0,80005ed6 <sys_mmap+0x11c>
    printf("mmap:get flags");
    return -1;
  }
  if(argfd(4,&fd,&f) < 0){
    80005e1a:	fa840613          	addi	a2,s0,-88
    80005e1e:	fb840593          	addi	a1,s0,-72
    80005e22:	4511                	li	a0,4
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	36c080e7          	jalr	876(ra) # 80005190 <argfd>
    80005e2c:	0a054f63          	bltz	a0,80005eea <sys_mmap+0x130>
    printf("mmap:get fd and file");
    return -1;
  }
  if(argint(5,&offset) < 0){
    80005e30:	fb440593          	addi	a1,s0,-76
    80005e34:	4515                	li	a0,5
    80005e36:	ffffd097          	auipc	ra,0xffffd
    80005e3a:	f42080e7          	jalr	-190(ra) # 80002d78 <argint>
    80005e3e:	0c054063          	bltz	a0,80005efe <sys_mmap+0x144>
    printf("mmap:get offset");
    return -1;
  }

  if((flags & MAP_PRIVATE) == 0){
    80005e42:	fbc42583          	lw	a1,-68(s0)
    80005e46:	0025f793          	andi	a5,a1,2
    80005e4a:	eb99                	bnez	a5,80005e60 <sys_mmap+0xa6>
    if(!f->writable && (prot & PROT_WRITE)){
    80005e4c:	fa843783          	ld	a5,-88(s0)
    80005e50:	0097c783          	lbu	a5,9(a5)
    80005e54:	e791                	bnez	a5,80005e60 <sys_mmap+0xa6>
    80005e56:	fc042783          	lw	a5,-64(s0)
    80005e5a:	8b89                	andi	a5,a5,2
      return 0xffffffffffffffff;
    80005e5c:	557d                	li	a0,-1
    if(!f->writable && (prot & PROT_WRITE)){
    80005e5e:	e79d                	bnez	a5,80005e8c <sys_mmap+0xd2>
    }
  }

  
  length = PGROUNDUP(length);
    80005e60:	fc442683          	lw	a3,-60(s0)
    80005e64:	6785                	lui	a5,0x1
    80005e66:	37fd                	addiw	a5,a5,-1
    80005e68:	9ebd                	addw	a3,a3,a5
    80005e6a:	77fd                	lui	a5,0xfffff
    80005e6c:	8efd                	and	a3,a3,a5
    80005e6e:	2681                	sext.w	a3,a3
    80005e70:	fcd42223          	sw	a3,-60(s0)

  //寻找可用的vma
  for(int i = 0;i < VMASIZE; ++i){
    80005e74:	19090793          	addi	a5,s2,400
    80005e78:	4481                	li	s1,0
    80005e7a:	4641                	li	a2,16
    struct VMA *vma = &p->vma[i];
    if(vma->valid == 0){//找到了一个可用的
    80005e7c:	4398                	lw	a4,0(a5)
    80005e7e:	cb51                	beqz	a4,80005f12 <sys_mmap+0x158>
  for(int i = 0;i < VMASIZE; ++i){
    80005e80:	2485                	addiw	s1,s1,1
    80005e82:	03078793          	addi	a5,a5,48 # fffffffffffff030 <end+0xffffffff7ffcd030>
    80005e86:	fec49be3          	bne	s1,a2,80005e7c <sys_mmap+0xc2>
      filedup(vma->f);
      return vma->address;
    }    
  }

  return 0xffffffffffffffff;
    80005e8a:	557d                	li	a0,-1
}
    80005e8c:	60e6                	ld	ra,88(sp)
    80005e8e:	6446                	ld	s0,80(sp)
    80005e90:	64a6                	ld	s1,72(sp)
    80005e92:	6906                	ld	s2,64(sp)
    80005e94:	79e2                	ld	s3,56(sp)
    80005e96:	6125                	addi	sp,sp,96
    80005e98:	8082                	ret
    printf("mmap:get st");
    80005e9a:	00003517          	auipc	a0,0x3
    80005e9e:	91e50513          	addi	a0,a0,-1762 # 800087b8 <syscalls+0x338>
    80005ea2:	ffffa097          	auipc	ra,0xffffa
    80005ea6:	6d8080e7          	jalr	1752(ra) # 8000057a <printf>
    return -1;
    80005eaa:	557d                	li	a0,-1
    80005eac:	b7c5                	j	80005e8c <sys_mmap+0xd2>
    printf("mmap:get len");
    80005eae:	00003517          	auipc	a0,0x3
    80005eb2:	91a50513          	addi	a0,a0,-1766 # 800087c8 <syscalls+0x348>
    80005eb6:	ffffa097          	auipc	ra,0xffffa
    80005eba:	6c4080e7          	jalr	1732(ra) # 8000057a <printf>
    return -1;
    80005ebe:	557d                	li	a0,-1
    80005ec0:	b7f1                	j	80005e8c <sys_mmap+0xd2>
    printf("mmap:get prot");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	91650513          	addi	a0,a0,-1770 # 800087d8 <syscalls+0x358>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	6b0080e7          	jalr	1712(ra) # 8000057a <printf>
    return -1;
    80005ed2:	557d                	li	a0,-1
    80005ed4:	bf65                	j	80005e8c <sys_mmap+0xd2>
    printf("mmap:get flags");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	91250513          	addi	a0,a0,-1774 # 800087e8 <syscalls+0x368>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	69c080e7          	jalr	1692(ra) # 8000057a <printf>
    return -1;
    80005ee6:	557d                	li	a0,-1
    80005ee8:	b755                	j	80005e8c <sys_mmap+0xd2>
    printf("mmap:get fd and file");
    80005eea:	00003517          	auipc	a0,0x3
    80005eee:	90e50513          	addi	a0,a0,-1778 # 800087f8 <syscalls+0x378>
    80005ef2:	ffffa097          	auipc	ra,0xffffa
    80005ef6:	688080e7          	jalr	1672(ra) # 8000057a <printf>
    return -1;
    80005efa:	557d                	li	a0,-1
    80005efc:	bf41                	j	80005e8c <sys_mmap+0xd2>
    printf("mmap:get offset");
    80005efe:	00003517          	auipc	a0,0x3
    80005f02:	91250513          	addi	a0,a0,-1774 # 80008810 <syscalls+0x390>
    80005f06:	ffffa097          	auipc	ra,0xffffa
    80005f0a:	674080e7          	jalr	1652(ra) # 8000057a <printf>
    return -1;
    80005f0e:	557d                	li	a0,-1
    80005f10:	bfb5                	j	80005e8c <sys_mmap+0xd2>
      vma->valid = 1;
    80005f12:	00149993          	slli	s3,s1,0x1
    80005f16:	009987b3          	add	a5,s3,s1
    80005f1a:	0792                	slli	a5,a5,0x4
    80005f1c:	97ca                	add	a5,a5,s2
    80005f1e:	4705                	li	a4,1
    80005f20:	18e7a823          	sw	a4,400(a5)
      vma->address = p->sz;
    80005f24:	04893703          	ld	a4,72(s2)
    80005f28:	16e7b423          	sd	a4,360(a5)
      vma->length = length;
    80005f2c:	16d7b823          	sd	a3,368(a5)
      vma->prot = prot;
    80005f30:	fc042603          	lw	a2,-64(s0)
    80005f34:	16c7ac23          	sw	a2,376(a5)
      vma->flags = flags;
    80005f38:	16b7ae23          	sw	a1,380(a5)
      vma->offset = offset;
    80005f3c:	fb442603          	lw	a2,-76(s0)
    80005f40:	18c7a023          	sw	a2,384(a5)
      vma->f = f;
    80005f44:	fa843503          	ld	a0,-88(s0)
    80005f48:	18a7b423          	sd	a0,392(a5)
      p->sz += vma->length;
    80005f4c:	96ba                	add	a3,a3,a4
    80005f4e:	04d93423          	sd	a3,72(s2)
      filedup(vma->f);
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	802080e7          	jalr	-2046(ra) # 80004754 <filedup>
      return vma->address;
    80005f5a:	94ce                	add	s1,s1,s3
    80005f5c:	0492                	slli	s1,s1,0x4
    80005f5e:	9926                	add	s2,s2,s1
    80005f60:	16893503          	ld	a0,360(s2)
    80005f64:	b725                	j	80005e8c <sys_mmap+0xd2>

0000000080005f66 <sys_munmap>:


uint64
sys_munmap(void){
    80005f66:	7139                	addi	sp,sp,-64
    80005f68:	fc06                	sd	ra,56(sp)
    80005f6a:	f822                	sd	s0,48(sp)
    80005f6c:	f426                	sd	s1,40(sp)
    80005f6e:	f04a                	sd	s2,32(sp)
    80005f70:	ec4e                	sd	s3,24(sp)
    80005f72:	0080                	addi	s0,sp,64
  uint64 start_address;
  int length;

  if(argaddr(0,&start_address) < 0){
    80005f74:	fc840593          	addi	a1,s0,-56
    80005f78:	4501                	li	a0,0
    80005f7a:	ffffd097          	auipc	ra,0xffffd
    80005f7e:	e20080e7          	jalr	-480(ra) # 80002d9a <argaddr>
    80005f82:	02054863          	bltz	a0,80005fb2 <sys_munmap+0x4c>
    printf("mmap:get st");
    return -1;
  }
  if(argint(1,&length) < 0){
    80005f86:	fc440593          	addi	a1,s0,-60
    80005f8a:	4505                	li	a0,1
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	dec080e7          	jalr	-532(ra) # 80002d78 <argint>
    80005f94:	02054963          	bltz	a0,80005fc6 <sys_munmap+0x60>
    return -1;
  }
  
  
  
  struct proc *p = myproc();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	aee080e7          	jalr	-1298(ra) # 80001a86 <myproc>
    80005fa0:	892a                	mv	s2,a0
  for(int i = 0;i < VMASIZE; ++i){
    struct VMA *vma = &p->vma[i];
    if(vma->valid == 1 && start_address >= vma->address && start_address <= vma->address + vma->length){
    80005fa2:	fc843803          	ld	a6,-56(s0)
    80005fa6:	16850793          	addi	a5,a0,360
  for(int i = 0;i < VMASIZE; ++i){
    80005faa:	4481                	li	s1,0
    if(vma->valid == 1 && start_address >= vma->address && start_address <= vma->address + vma->length){
    80005fac:	4605                	li	a2,1
  for(int i = 0;i < VMASIZE; ++i){
    80005fae:	45c1                	li	a1,16
    80005fb0:	a0cd                	j	80006092 <sys_munmap+0x12c>
    printf("mmap:get st");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	80650513          	addi	a0,a0,-2042 # 800087b8 <syscalls+0x338>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	5c0080e7          	jalr	1472(ra) # 8000057a <printf>
    return -1;
    80005fc2:	557d                	li	a0,-1
    80005fc4:	a2e1                	j	8000618c <sys_munmap+0x226>
    printf("mmap:get len");
    80005fc6:	00003517          	auipc	a0,0x3
    80005fca:	80250513          	addi	a0,a0,-2046 # 800087c8 <syscalls+0x348>
    80005fce:	ffffa097          	auipc	ra,0xffffa
    80005fd2:	5ac080e7          	jalr	1452(ra) # 8000057a <printf>
    return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	aa55                	j	8000618c <sys_munmap+0x226>
      if(vma->flags & MAP_SHARED){
        begin_op();
        ilock(vma->f->ip);
        if(writei(vma->f->ip,1,start_address,0,length) < 0){
          printf("%p\n %d\n",start_address,length);
    80005fda:	fc442603          	lw	a2,-60(s0)
    80005fde:	fc843583          	ld	a1,-56(s0)
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	83e50513          	addi	a0,a0,-1986 # 80008820 <syscalls+0x3a0>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	590080e7          	jalr	1424(ra) # 8000057a <printf>
          printf("write back to file error\n");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	83650513          	addi	a0,a0,-1994 # 80008828 <syscalls+0x3a8>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	580080e7          	jalr	1408(ra) # 8000057a <printf>
          iunlock(vma->f->ip);
    80006002:	1889b783          	ld	a5,392(s3)
    80006006:	6f88                	ld	a0,24(a5)
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	9ba080e7          	jalr	-1606(ra) # 800039c2 <iunlock>
          return -1;
    80006010:	557d                	li	a0,-1
    80006012:	aaad                	j	8000618c <sys_munmap+0x226>
        end_op();
      }
      start_address = PGROUNDDOWN(start_address);
      length = PGROUNDUP(length);
      uvmunmap(p->pagetable,start_address,length/PGSIZE,1);
      if(start_address == vma->address && vma->length == length){
    80006014:	fc442603          	lw	a2,-60(s0)
    80006018:	00149793          	slli	a5,s1,0x1
    8000601c:	97a6                	add	a5,a5,s1
    8000601e:	0792                	slli	a5,a5,0x4
    80006020:	97ca                	add	a5,a5,s2
    80006022:	1707b783          	ld	a5,368(a5)
    80006026:	02c78763          	beq	a5,a2,80006054 <sys_munmap+0xee>
        vma->f->ref--;
        vma->valid = 0;
      }
      else if(start_address == vma->address){
        vma->address += length;
    8000602a:	00149693          	slli	a3,s1,0x1
    8000602e:	009687b3          	add	a5,a3,s1
    80006032:	0792                	slli	a5,a5,0x4
    80006034:	97ca                	add	a5,a5,s2
    80006036:	9732                	add	a4,a4,a2
    80006038:	16e7b423          	sd	a4,360(a5)
        vma->length -= length;
    8000603c:	1707b703          	ld	a4,368(a5)
    80006040:	8f11                	sub	a4,a4,a2
    80006042:	16e7b823          	sd	a4,368(a5)
        vma->offset += length;
    80006046:	1807a703          	lw	a4,384(a5)
    8000604a:	9e39                	addw	a2,a2,a4
    8000604c:	18c7a023          	sw	a2,384(a5)
        vma->length -= length;
      }
      else{
        panic("munmap !!!");
      }
      return 0;
    80006050:	4501                	li	a0,0
    80006052:	aa2d                	j	8000618c <sys_munmap+0x226>
        vma->f->ref--;
    80006054:	00149793          	slli	a5,s1,0x1
    80006058:	00978733          	add	a4,a5,s1
    8000605c:	0712                	slli	a4,a4,0x4
    8000605e:	974a                	add	a4,a4,s2
    80006060:	18873683          	ld	a3,392(a4)
    80006064:	42d8                	lw	a4,4(a3)
    80006066:	377d                	addiw	a4,a4,-1
    80006068:	c2d8                	sw	a4,4(a3)
        vma->valid = 0;
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	0792                	slli	a5,a5,0x4
    8000606e:	993e                	add	s2,s2,a5
    80006070:	18092823          	sw	zero,400(s2)
      return 0;
    80006074:	4501                	li	a0,0
        vma->valid = 0;
    80006076:	aa19                	j	8000618c <sys_munmap+0x226>
        panic("munmap !!!");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	7d050513          	addi	a0,a0,2000 # 80008848 <syscalls+0x3c8>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4b0080e7          	jalr	1200(ra) # 80000530 <panic>
  for(int i = 0;i < VMASIZE; ++i){
    80006088:	2485                	addiw	s1,s1,1
    8000608a:	03078793          	addi	a5,a5,48
    8000608e:	0eb48e63          	beq	s1,a1,8000618a <sys_munmap+0x224>
    if(vma->valid == 1 && start_address >= vma->address && start_address <= vma->address + vma->length){
    80006092:	5798                	lw	a4,40(a5)
    80006094:	fec71ae3          	bne	a4,a2,80006088 <sys_munmap+0x122>
    80006098:	6398                	ld	a4,0(a5)
    8000609a:	fee867e3          	bltu	a6,a4,80006088 <sys_munmap+0x122>
    8000609e:	6794                	ld	a3,8(a5)
    800060a0:	9736                	add	a4,a4,a3
    800060a2:	ff0763e3          	bltu	a4,a6,80006088 <sys_munmap+0x122>
      if(vma->flags & MAP_SHARED){
    800060a6:	00149793          	slli	a5,s1,0x1
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	0792                	slli	a5,a5,0x4
    800060ae:	97ca                	add	a5,a5,s2
    800060b0:	17c7a783          	lw	a5,380(a5)
    800060b4:	8b85                	andi	a5,a5,1
    800060b6:	c3a5                	beqz	a5,80006116 <sys_munmap+0x1b0>
        begin_op();
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	21a080e7          	jalr	538(ra) # 800042d2 <begin_op>
        ilock(vma->f->ip);
    800060c0:	00149993          	slli	s3,s1,0x1
    800060c4:	99a6                	add	s3,s3,s1
    800060c6:	0992                	slli	s3,s3,0x4
    800060c8:	99ca                	add	s3,s3,s2
    800060ca:	1889b783          	ld	a5,392(s3)
    800060ce:	6f88                	ld	a0,24(a5)
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	81a080e7          	jalr	-2022(ra) # 800038ea <ilock>
        if(writei(vma->f->ip,1,start_address,0,length) < 0){
    800060d8:	1889b783          	ld	a5,392(s3)
    800060dc:	fc442703          	lw	a4,-60(s0)
    800060e0:	4681                	li	a3,0
    800060e2:	fc843603          	ld	a2,-56(s0)
    800060e6:	4585                	li	a1,1
    800060e8:	6f88                	ld	a0,24(a5)
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	bc2080e7          	jalr	-1086(ra) # 80003cac <writei>
    800060f2:	ee0544e3          	bltz	a0,80005fda <sys_munmap+0x74>
        iunlock(vma->f->ip);
    800060f6:	00149793          	slli	a5,s1,0x1
    800060fa:	97a6                	add	a5,a5,s1
    800060fc:	0792                	slli	a5,a5,0x4
    800060fe:	97ca                	add	a5,a5,s2
    80006100:	1887b783          	ld	a5,392(a5)
    80006104:	6f88                	ld	a0,24(a5)
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	8bc080e7          	jalr	-1860(ra) # 800039c2 <iunlock>
        end_op();
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	244080e7          	jalr	580(ra) # 80004352 <end_op>
      start_address = PGROUNDDOWN(start_address);
    80006116:	75fd                	lui	a1,0xfffff
    80006118:	fc843783          	ld	a5,-56(s0)
    8000611c:	8dfd                	and	a1,a1,a5
    8000611e:	fcb43423          	sd	a1,-56(s0)
      length = PGROUNDUP(length);
    80006122:	fc442603          	lw	a2,-60(s0)
    80006126:	6785                	lui	a5,0x1
    80006128:	37fd                	addiw	a5,a5,-1
    8000612a:	9e3d                	addw	a2,a2,a5
    8000612c:	77fd                	lui	a5,0xfffff
    8000612e:	8ff1                	and	a5,a5,a2
    80006130:	fcf42223          	sw	a5,-60(s0)
      uvmunmap(p->pagetable,start_address,length/PGSIZE,1);
    80006134:	4685                	li	a3,1
    80006136:	40c6561b          	sraiw	a2,a2,0xc
    8000613a:	05093503          	ld	a0,80(s2)
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	11c080e7          	jalr	284(ra) # 8000125a <uvmunmap>
      if(start_address == vma->address && vma->length == length){
    80006146:	00149793          	slli	a5,s1,0x1
    8000614a:	97a6                	add	a5,a5,s1
    8000614c:	0792                	slli	a5,a5,0x4
    8000614e:	97ca                	add	a5,a5,s2
    80006150:	1687b703          	ld	a4,360(a5) # fffffffffffff168 <end+0xffffffff7ffcd168>
    80006154:	fc843683          	ld	a3,-56(s0)
    80006158:	ead70ee3          	beq	a4,a3,80006014 <sys_munmap+0xae>
      else if(start_address + length == vma->address + vma->length){
    8000615c:	fc442583          	lw	a1,-60(s0)
    80006160:	00149793          	slli	a5,s1,0x1
    80006164:	97a6                	add	a5,a5,s1
    80006166:	0792                	slli	a5,a5,0x4
    80006168:	97ca                	add	a5,a5,s2
    8000616a:	1707b603          	ld	a2,368(a5)
    8000616e:	96ae                	add	a3,a3,a1
    80006170:	9732                	add	a4,a4,a2
    80006172:	f0e693e3          	bne	a3,a4,80006078 <sys_munmap+0x112>
        vma->length -= length;
    80006176:	00149793          	slli	a5,s1,0x1
    8000617a:	97a6                	add	a5,a5,s1
    8000617c:	0792                	slli	a5,a5,0x4
    8000617e:	993e                	add	s2,s2,a5
    80006180:	8e0d                	sub	a2,a2,a1
    80006182:	16c93823          	sd	a2,368(s2)
      return 0;
    80006186:	4501                	li	a0,0
    80006188:	a011                	j	8000618c <sys_munmap+0x226>
    }
  }
  return 0;//这里必须得返回0，因为有可能会出现mmap了3个page，但是实际上文件只有1个page大小，导致munmap的时候找不到
    8000618a:	4501                	li	a0,0
}
    8000618c:	70e2                	ld	ra,56(sp)
    8000618e:	7442                	ld	s0,48(sp)
    80006190:	74a2                	ld	s1,40(sp)
    80006192:	7902                	ld	s2,32(sp)
    80006194:	69e2                	ld	s3,24(sp)
    80006196:	6121                	addi	sp,sp,64
    80006198:	8082                	ret
    8000619a:	0000                	unimp
    8000619c:	0000                	unimp
	...

00000000800061a0 <kernelvec>:
    800061a0:	7111                	addi	sp,sp,-256
    800061a2:	e006                	sd	ra,0(sp)
    800061a4:	e40a                	sd	sp,8(sp)
    800061a6:	e80e                	sd	gp,16(sp)
    800061a8:	ec12                	sd	tp,24(sp)
    800061aa:	f016                	sd	t0,32(sp)
    800061ac:	f41a                	sd	t1,40(sp)
    800061ae:	f81e                	sd	t2,48(sp)
    800061b0:	fc22                	sd	s0,56(sp)
    800061b2:	e0a6                	sd	s1,64(sp)
    800061b4:	e4aa                	sd	a0,72(sp)
    800061b6:	e8ae                	sd	a1,80(sp)
    800061b8:	ecb2                	sd	a2,88(sp)
    800061ba:	f0b6                	sd	a3,96(sp)
    800061bc:	f4ba                	sd	a4,104(sp)
    800061be:	f8be                	sd	a5,112(sp)
    800061c0:	fcc2                	sd	a6,120(sp)
    800061c2:	e146                	sd	a7,128(sp)
    800061c4:	e54a                	sd	s2,136(sp)
    800061c6:	e94e                	sd	s3,144(sp)
    800061c8:	ed52                	sd	s4,152(sp)
    800061ca:	f156                	sd	s5,160(sp)
    800061cc:	f55a                	sd	s6,168(sp)
    800061ce:	f95e                	sd	s7,176(sp)
    800061d0:	fd62                	sd	s8,184(sp)
    800061d2:	e1e6                	sd	s9,192(sp)
    800061d4:	e5ea                	sd	s10,200(sp)
    800061d6:	e9ee                	sd	s11,208(sp)
    800061d8:	edf2                	sd	t3,216(sp)
    800061da:	f1f6                	sd	t4,224(sp)
    800061dc:	f5fa                	sd	t5,232(sp)
    800061de:	f9fe                	sd	t6,240(sp)
    800061e0:	f56fc0ef          	jal	ra,80002936 <kerneltrap>
    800061e4:	6082                	ld	ra,0(sp)
    800061e6:	6122                	ld	sp,8(sp)
    800061e8:	61c2                	ld	gp,16(sp)
    800061ea:	7282                	ld	t0,32(sp)
    800061ec:	7322                	ld	t1,40(sp)
    800061ee:	73c2                	ld	t2,48(sp)
    800061f0:	7462                	ld	s0,56(sp)
    800061f2:	6486                	ld	s1,64(sp)
    800061f4:	6526                	ld	a0,72(sp)
    800061f6:	65c6                	ld	a1,80(sp)
    800061f8:	6666                	ld	a2,88(sp)
    800061fa:	7686                	ld	a3,96(sp)
    800061fc:	7726                	ld	a4,104(sp)
    800061fe:	77c6                	ld	a5,112(sp)
    80006200:	7866                	ld	a6,120(sp)
    80006202:	688a                	ld	a7,128(sp)
    80006204:	692a                	ld	s2,136(sp)
    80006206:	69ca                	ld	s3,144(sp)
    80006208:	6a6a                	ld	s4,152(sp)
    8000620a:	7a8a                	ld	s5,160(sp)
    8000620c:	7b2a                	ld	s6,168(sp)
    8000620e:	7bca                	ld	s7,176(sp)
    80006210:	7c6a                	ld	s8,184(sp)
    80006212:	6c8e                	ld	s9,192(sp)
    80006214:	6d2e                	ld	s10,200(sp)
    80006216:	6dce                	ld	s11,208(sp)
    80006218:	6e6e                	ld	t3,216(sp)
    8000621a:	7e8e                	ld	t4,224(sp)
    8000621c:	7f2e                	ld	t5,232(sp)
    8000621e:	7fce                	ld	t6,240(sp)
    80006220:	6111                	addi	sp,sp,256
    80006222:	10200073          	sret
    80006226:	00000013          	nop
    8000622a:	00000013          	nop
    8000622e:	0001                	nop

0000000080006230 <timervec>:
    80006230:	34051573          	csrrw	a0,mscratch,a0
    80006234:	e10c                	sd	a1,0(a0)
    80006236:	e510                	sd	a2,8(a0)
    80006238:	e914                	sd	a3,16(a0)
    8000623a:	6d0c                	ld	a1,24(a0)
    8000623c:	7110                	ld	a2,32(a0)
    8000623e:	6194                	ld	a3,0(a1)
    80006240:	96b2                	add	a3,a3,a2
    80006242:	e194                	sd	a3,0(a1)
    80006244:	4589                	li	a1,2
    80006246:	14459073          	csrw	sip,a1
    8000624a:	6914                	ld	a3,16(a0)
    8000624c:	6510                	ld	a2,8(a0)
    8000624e:	610c                	ld	a1,0(a0)
    80006250:	34051573          	csrrw	a0,mscratch,a0
    80006254:	30200073          	mret
	...

000000008000625a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000625a:	1141                	addi	sp,sp,-16
    8000625c:	e422                	sd	s0,8(sp)
    8000625e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006260:	0c0007b7          	lui	a5,0xc000
    80006264:	4705                	li	a4,1
    80006266:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006268:	c3d8                	sw	a4,4(a5)
}
    8000626a:	6422                	ld	s0,8(sp)
    8000626c:	0141                	addi	sp,sp,16
    8000626e:	8082                	ret

0000000080006270 <plicinithart>:

void
plicinithart(void)
{
    80006270:	1141                	addi	sp,sp,-16
    80006272:	e406                	sd	ra,8(sp)
    80006274:	e022                	sd	s0,0(sp)
    80006276:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006278:	ffffb097          	auipc	ra,0xffffb
    8000627c:	7e2080e7          	jalr	2018(ra) # 80001a5a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006280:	0085171b          	slliw	a4,a0,0x8
    80006284:	0c0027b7          	lui	a5,0xc002
    80006288:	97ba                	add	a5,a5,a4
    8000628a:	40200713          	li	a4,1026
    8000628e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006292:	00d5151b          	slliw	a0,a0,0xd
    80006296:	0c2017b7          	lui	a5,0xc201
    8000629a:	953e                	add	a0,a0,a5
    8000629c:	00052023          	sw	zero,0(a0)
}
    800062a0:	60a2                	ld	ra,8(sp)
    800062a2:	6402                	ld	s0,0(sp)
    800062a4:	0141                	addi	sp,sp,16
    800062a6:	8082                	ret

00000000800062a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062a8:	1141                	addi	sp,sp,-16
    800062aa:	e406                	sd	ra,8(sp)
    800062ac:	e022                	sd	s0,0(sp)
    800062ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	7aa080e7          	jalr	1962(ra) # 80001a5a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062b8:	00d5179b          	slliw	a5,a0,0xd
    800062bc:	0c201537          	lui	a0,0xc201
    800062c0:	953e                	add	a0,a0,a5
  return irq;
}
    800062c2:	4148                	lw	a0,4(a0)
    800062c4:	60a2                	ld	ra,8(sp)
    800062c6:	6402                	ld	s0,0(sp)
    800062c8:	0141                	addi	sp,sp,16
    800062ca:	8082                	ret

00000000800062cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062cc:	1101                	addi	sp,sp,-32
    800062ce:	ec06                	sd	ra,24(sp)
    800062d0:	e822                	sd	s0,16(sp)
    800062d2:	e426                	sd	s1,8(sp)
    800062d4:	1000                	addi	s0,sp,32
    800062d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	782080e7          	jalr	1922(ra) # 80001a5a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062e0:	00d5151b          	slliw	a0,a0,0xd
    800062e4:	0c2017b7          	lui	a5,0xc201
    800062e8:	97aa                	add	a5,a5,a0
    800062ea:	c3c4                	sw	s1,4(a5)
}
    800062ec:	60e2                	ld	ra,24(sp)
    800062ee:	6442                	ld	s0,16(sp)
    800062f0:	64a2                	ld	s1,8(sp)
    800062f2:	6105                	addi	sp,sp,32
    800062f4:	8082                	ret

00000000800062f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062f6:	1141                	addi	sp,sp,-16
    800062f8:	e406                	sd	ra,8(sp)
    800062fa:	e022                	sd	s0,0(sp)
    800062fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062fe:	479d                	li	a5,7
    80006300:	06a7c963          	blt	a5,a0,80006372 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006304:	00029797          	auipc	a5,0x29
    80006308:	cfc78793          	addi	a5,a5,-772 # 8002f000 <disk>
    8000630c:	00a78733          	add	a4,a5,a0
    80006310:	6789                	lui	a5,0x2
    80006312:	97ba                	add	a5,a5,a4
    80006314:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006318:	e7ad                	bnez	a5,80006382 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000631a:	00451793          	slli	a5,a0,0x4
    8000631e:	0002b717          	auipc	a4,0x2b
    80006322:	ce270713          	addi	a4,a4,-798 # 80031000 <disk+0x2000>
    80006326:	6314                	ld	a3,0(a4)
    80006328:	96be                	add	a3,a3,a5
    8000632a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000632e:	6314                	ld	a3,0(a4)
    80006330:	96be                	add	a3,a3,a5
    80006332:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006336:	6314                	ld	a3,0(a4)
    80006338:	96be                	add	a3,a3,a5
    8000633a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000633e:	6318                	ld	a4,0(a4)
    80006340:	97ba                	add	a5,a5,a4
    80006342:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006346:	00029797          	auipc	a5,0x29
    8000634a:	cba78793          	addi	a5,a5,-838 # 8002f000 <disk>
    8000634e:	97aa                	add	a5,a5,a0
    80006350:	6509                	lui	a0,0x2
    80006352:	953e                	add	a0,a0,a5
    80006354:	4785                	li	a5,1
    80006356:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000635a:	0002b517          	auipc	a0,0x2b
    8000635e:	cbe50513          	addi	a0,a0,-834 # 80031018 <disk+0x2018>
    80006362:	ffffc097          	auipc	ra,0xffffc
    80006366:	16e080e7          	jalr	366(ra) # 800024d0 <wakeup>
}
    8000636a:	60a2                	ld	ra,8(sp)
    8000636c:	6402                	ld	s0,0(sp)
    8000636e:	0141                	addi	sp,sp,16
    80006370:	8082                	ret
    panic("free_desc 1");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	4e650513          	addi	a0,a0,1254 # 80008858 <syscalls+0x3d8>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1b6080e7          	jalr	438(ra) # 80000530 <panic>
    panic("free_desc 2");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	4e650513          	addi	a0,a0,1254 # 80008868 <syscalls+0x3e8>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1a6080e7          	jalr	422(ra) # 80000530 <panic>

0000000080006392 <virtio_disk_init>:
{
    80006392:	1101                	addi	sp,sp,-32
    80006394:	ec06                	sd	ra,24(sp)
    80006396:	e822                	sd	s0,16(sp)
    80006398:	e426                	sd	s1,8(sp)
    8000639a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000639c:	00002597          	auipc	a1,0x2
    800063a0:	4dc58593          	addi	a1,a1,1244 # 80008878 <syscalls+0x3f8>
    800063a4:	0002b517          	auipc	a0,0x2b
    800063a8:	d8450513          	addi	a0,a0,-636 # 80031128 <disk+0x2128>
    800063ac:	ffffa097          	auipc	ra,0xffffa
    800063b0:	79a080e7          	jalr	1946(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063b4:	100017b7          	lui	a5,0x10001
    800063b8:	4398                	lw	a4,0(a5)
    800063ba:	2701                	sext.w	a4,a4
    800063bc:	747277b7          	lui	a5,0x74727
    800063c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063c4:	0ef71163          	bne	a4,a5,800064a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063c8:	100017b7          	lui	a5,0x10001
    800063cc:	43dc                	lw	a5,4(a5)
    800063ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063d0:	4705                	li	a4,1
    800063d2:	0ce79a63          	bne	a5,a4,800064a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063d6:	100017b7          	lui	a5,0x10001
    800063da:	479c                	lw	a5,8(a5)
    800063dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063de:	4709                	li	a4,2
    800063e0:	0ce79363          	bne	a5,a4,800064a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063e4:	100017b7          	lui	a5,0x10001
    800063e8:	47d8                	lw	a4,12(a5)
    800063ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063ec:	554d47b7          	lui	a5,0x554d4
    800063f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063f4:	0af71963          	bne	a4,a5,800064a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063f8:	100017b7          	lui	a5,0x10001
    800063fc:	4705                	li	a4,1
    800063fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006400:	470d                	li	a4,3
    80006402:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006404:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006406:	c7ffe737          	lui	a4,0xc7ffe
    8000640a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000640e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006410:	2701                	sext.w	a4,a4
    80006412:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006414:	472d                	li	a4,11
    80006416:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006418:	473d                	li	a4,15
    8000641a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000641c:	6705                	lui	a4,0x1
    8000641e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006420:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006424:	5bdc                	lw	a5,52(a5)
    80006426:	2781                	sext.w	a5,a5
  if(max == 0)
    80006428:	c7d9                	beqz	a5,800064b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000642a:	471d                	li	a4,7
    8000642c:	08f77d63          	bgeu	a4,a5,800064c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006430:	100014b7          	lui	s1,0x10001
    80006434:	47a1                	li	a5,8
    80006436:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006438:	6609                	lui	a2,0x2
    8000643a:	4581                	li	a1,0
    8000643c:	00029517          	auipc	a0,0x29
    80006440:	bc450513          	addi	a0,a0,-1084 # 8002f000 <disk>
    80006444:	ffffb097          	auipc	ra,0xffffb
    80006448:	88e080e7          	jalr	-1906(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000644c:	00029717          	auipc	a4,0x29
    80006450:	bb470713          	addi	a4,a4,-1100 # 8002f000 <disk>
    80006454:	00c75793          	srli	a5,a4,0xc
    80006458:	2781                	sext.w	a5,a5
    8000645a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000645c:	0002b797          	auipc	a5,0x2b
    80006460:	ba478793          	addi	a5,a5,-1116 # 80031000 <disk+0x2000>
    80006464:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006466:	00029717          	auipc	a4,0x29
    8000646a:	c1a70713          	addi	a4,a4,-998 # 8002f080 <disk+0x80>
    8000646e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006470:	0002a717          	auipc	a4,0x2a
    80006474:	b9070713          	addi	a4,a4,-1136 # 80030000 <disk+0x1000>
    80006478:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000647a:	4705                	li	a4,1
    8000647c:	00e78c23          	sb	a4,24(a5)
    80006480:	00e78ca3          	sb	a4,25(a5)
    80006484:	00e78d23          	sb	a4,26(a5)
    80006488:	00e78da3          	sb	a4,27(a5)
    8000648c:	00e78e23          	sb	a4,28(a5)
    80006490:	00e78ea3          	sb	a4,29(a5)
    80006494:	00e78f23          	sb	a4,30(a5)
    80006498:	00e78fa3          	sb	a4,31(a5)
}
    8000649c:	60e2                	ld	ra,24(sp)
    8000649e:	6442                	ld	s0,16(sp)
    800064a0:	64a2                	ld	s1,8(sp)
    800064a2:	6105                	addi	sp,sp,32
    800064a4:	8082                	ret
    panic("could not find virtio disk");
    800064a6:	00002517          	auipc	a0,0x2
    800064aa:	3e250513          	addi	a0,a0,994 # 80008888 <syscalls+0x408>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	082080e7          	jalr	130(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    800064b6:	00002517          	auipc	a0,0x2
    800064ba:	3f250513          	addi	a0,a0,1010 # 800088a8 <syscalls+0x428>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	072080e7          	jalr	114(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	40250513          	addi	a0,a0,1026 # 800088c8 <syscalls+0x448>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	062080e7          	jalr	98(ra) # 80000530 <panic>

00000000800064d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064d6:	7159                	addi	sp,sp,-112
    800064d8:	f486                	sd	ra,104(sp)
    800064da:	f0a2                	sd	s0,96(sp)
    800064dc:	eca6                	sd	s1,88(sp)
    800064de:	e8ca                	sd	s2,80(sp)
    800064e0:	e4ce                	sd	s3,72(sp)
    800064e2:	e0d2                	sd	s4,64(sp)
    800064e4:	fc56                	sd	s5,56(sp)
    800064e6:	f85a                	sd	s6,48(sp)
    800064e8:	f45e                	sd	s7,40(sp)
    800064ea:	f062                	sd	s8,32(sp)
    800064ec:	ec66                	sd	s9,24(sp)
    800064ee:	e86a                	sd	s10,16(sp)
    800064f0:	1880                	addi	s0,sp,112
    800064f2:	892a                	mv	s2,a0
    800064f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064f6:	00c52c83          	lw	s9,12(a0)
    800064fa:	001c9c9b          	slliw	s9,s9,0x1
    800064fe:	1c82                	slli	s9,s9,0x20
    80006500:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006504:	0002b517          	auipc	a0,0x2b
    80006508:	c2450513          	addi	a0,a0,-988 # 80031128 <disk+0x2128>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	6ca080e7          	jalr	1738(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006514:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006516:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006518:	00029b97          	auipc	s7,0x29
    8000651c:	ae8b8b93          	addi	s7,s7,-1304 # 8002f000 <disk>
    80006520:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006522:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006524:	8a4e                	mv	s4,s3
    80006526:	a051                	j	800065aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006528:	00fb86b3          	add	a3,s7,a5
    8000652c:	96da                	add	a3,a3,s6
    8000652e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006532:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006534:	0207c563          	bltz	a5,8000655e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006538:	2485                	addiw	s1,s1,1
    8000653a:	0711                	addi	a4,a4,4
    8000653c:	25548063          	beq	s1,s5,8000677c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006540:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006542:	0002b697          	auipc	a3,0x2b
    80006546:	ad668693          	addi	a3,a3,-1322 # 80031018 <disk+0x2018>
    8000654a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000654c:	0006c583          	lbu	a1,0(a3)
    80006550:	fde1                	bnez	a1,80006528 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006552:	2785                	addiw	a5,a5,1
    80006554:	0685                	addi	a3,a3,1
    80006556:	ff879be3          	bne	a5,s8,8000654c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000655a:	57fd                	li	a5,-1
    8000655c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000655e:	02905a63          	blez	s1,80006592 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006562:	f9042503          	lw	a0,-112(s0)
    80006566:	00000097          	auipc	ra,0x0
    8000656a:	d90080e7          	jalr	-624(ra) # 800062f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000656e:	4785                	li	a5,1
    80006570:	0297d163          	bge	a5,s1,80006592 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006574:	f9442503          	lw	a0,-108(s0)
    80006578:	00000097          	auipc	ra,0x0
    8000657c:	d7e080e7          	jalr	-642(ra) # 800062f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006580:	4789                	li	a5,2
    80006582:	0097d863          	bge	a5,s1,80006592 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006586:	f9842503          	lw	a0,-104(s0)
    8000658a:	00000097          	auipc	ra,0x0
    8000658e:	d6c080e7          	jalr	-660(ra) # 800062f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006592:	0002b597          	auipc	a1,0x2b
    80006596:	b9658593          	addi	a1,a1,-1130 # 80031128 <disk+0x2128>
    8000659a:	0002b517          	auipc	a0,0x2b
    8000659e:	a7e50513          	addi	a0,a0,-1410 # 80031018 <disk+0x2018>
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	da8080e7          	jalr	-600(ra) # 8000234a <sleep>
  for(int i = 0; i < 3; i++){
    800065aa:	f9040713          	addi	a4,s0,-112
    800065ae:	84ce                	mv	s1,s3
    800065b0:	bf41                	j	80006540 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065b2:	20058713          	addi	a4,a1,512
    800065b6:	00471693          	slli	a3,a4,0x4
    800065ba:	00029717          	auipc	a4,0x29
    800065be:	a4670713          	addi	a4,a4,-1466 # 8002f000 <disk>
    800065c2:	9736                	add	a4,a4,a3
    800065c4:	4685                	li	a3,1
    800065c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065ca:	20058713          	addi	a4,a1,512
    800065ce:	00471693          	slli	a3,a4,0x4
    800065d2:	00029717          	auipc	a4,0x29
    800065d6:	a2e70713          	addi	a4,a4,-1490 # 8002f000 <disk>
    800065da:	9736                	add	a4,a4,a3
    800065dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065e4:	7679                	lui	a2,0xffffe
    800065e6:	963e                	add	a2,a2,a5
    800065e8:	0002b697          	auipc	a3,0x2b
    800065ec:	a1868693          	addi	a3,a3,-1512 # 80031000 <disk+0x2000>
    800065f0:	6298                	ld	a4,0(a3)
    800065f2:	9732                	add	a4,a4,a2
    800065f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065f6:	6298                	ld	a4,0(a3)
    800065f8:	9732                	add	a4,a4,a2
    800065fa:	4541                	li	a0,16
    800065fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065fe:	6298                	ld	a4,0(a3)
    80006600:	9732                	add	a4,a4,a2
    80006602:	4505                	li	a0,1
    80006604:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006608:	f9442703          	lw	a4,-108(s0)
    8000660c:	6288                	ld	a0,0(a3)
    8000660e:	962a                	add	a2,a2,a0
    80006610:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcc00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006614:	0712                	slli	a4,a4,0x4
    80006616:	6290                	ld	a2,0(a3)
    80006618:	963a                	add	a2,a2,a4
    8000661a:	05890513          	addi	a0,s2,88
    8000661e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006620:	6294                	ld	a3,0(a3)
    80006622:	96ba                	add	a3,a3,a4
    80006624:	40000613          	li	a2,1024
    80006628:	c690                	sw	a2,8(a3)
  if(write)
    8000662a:	140d0063          	beqz	s10,8000676a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000662e:	0002b697          	auipc	a3,0x2b
    80006632:	9d26b683          	ld	a3,-1582(a3) # 80031000 <disk+0x2000>
    80006636:	96ba                	add	a3,a3,a4
    80006638:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000663c:	00029817          	auipc	a6,0x29
    80006640:	9c480813          	addi	a6,a6,-1596 # 8002f000 <disk>
    80006644:	0002b517          	auipc	a0,0x2b
    80006648:	9bc50513          	addi	a0,a0,-1604 # 80031000 <disk+0x2000>
    8000664c:	6114                	ld	a3,0(a0)
    8000664e:	96ba                	add	a3,a3,a4
    80006650:	00c6d603          	lhu	a2,12(a3)
    80006654:	00166613          	ori	a2,a2,1
    80006658:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000665c:	f9842683          	lw	a3,-104(s0)
    80006660:	6110                	ld	a2,0(a0)
    80006662:	9732                	add	a4,a4,a2
    80006664:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006668:	20058613          	addi	a2,a1,512
    8000666c:	0612                	slli	a2,a2,0x4
    8000666e:	9642                	add	a2,a2,a6
    80006670:	577d                	li	a4,-1
    80006672:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006676:	00469713          	slli	a4,a3,0x4
    8000667a:	6114                	ld	a3,0(a0)
    8000667c:	96ba                	add	a3,a3,a4
    8000667e:	03078793          	addi	a5,a5,48
    80006682:	97c2                	add	a5,a5,a6
    80006684:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006686:	611c                	ld	a5,0(a0)
    80006688:	97ba                	add	a5,a5,a4
    8000668a:	4685                	li	a3,1
    8000668c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000668e:	611c                	ld	a5,0(a0)
    80006690:	97ba                	add	a5,a5,a4
    80006692:	4809                	li	a6,2
    80006694:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006698:	611c                	ld	a5,0(a0)
    8000669a:	973e                	add	a4,a4,a5
    8000669c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066a8:	6518                	ld	a4,8(a0)
    800066aa:	00275783          	lhu	a5,2(a4)
    800066ae:	8b9d                	andi	a5,a5,7
    800066b0:	0786                	slli	a5,a5,0x1
    800066b2:	97ba                	add	a5,a5,a4
    800066b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066bc:	6518                	ld	a4,8(a0)
    800066be:	00275783          	lhu	a5,2(a4)
    800066c2:	2785                	addiw	a5,a5,1
    800066c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066cc:	100017b7          	lui	a5,0x10001
    800066d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066d4:	00492703          	lw	a4,4(s2)
    800066d8:	4785                	li	a5,1
    800066da:	02f71163          	bne	a4,a5,800066fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066de:	0002b997          	auipc	s3,0x2b
    800066e2:	a4a98993          	addi	s3,s3,-1462 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    800066e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066e8:	85ce                	mv	a1,s3
    800066ea:	854a                	mv	a0,s2
    800066ec:	ffffc097          	auipc	ra,0xffffc
    800066f0:	c5e080e7          	jalr	-930(ra) # 8000234a <sleep>
  while(b->disk == 1) {
    800066f4:	00492783          	lw	a5,4(s2)
    800066f8:	fe9788e3          	beq	a5,s1,800066e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066fc:	f9042903          	lw	s2,-112(s0)
    80006700:	20090793          	addi	a5,s2,512
    80006704:	00479713          	slli	a4,a5,0x4
    80006708:	00029797          	auipc	a5,0x29
    8000670c:	8f878793          	addi	a5,a5,-1800 # 8002f000 <disk>
    80006710:	97ba                	add	a5,a5,a4
    80006712:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006716:	0002b997          	auipc	s3,0x2b
    8000671a:	8ea98993          	addi	s3,s3,-1814 # 80031000 <disk+0x2000>
    8000671e:	00491713          	slli	a4,s2,0x4
    80006722:	0009b783          	ld	a5,0(s3)
    80006726:	97ba                	add	a5,a5,a4
    80006728:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000672c:	854a                	mv	a0,s2
    8000672e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006732:	00000097          	auipc	ra,0x0
    80006736:	bc4080e7          	jalr	-1084(ra) # 800062f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000673a:	8885                	andi	s1,s1,1
    8000673c:	f0ed                	bnez	s1,8000671e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000673e:	0002b517          	auipc	a0,0x2b
    80006742:	9ea50513          	addi	a0,a0,-1558 # 80031128 <disk+0x2128>
    80006746:	ffffa097          	auipc	ra,0xffffa
    8000674a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
}
    8000674e:	70a6                	ld	ra,104(sp)
    80006750:	7406                	ld	s0,96(sp)
    80006752:	64e6                	ld	s1,88(sp)
    80006754:	6946                	ld	s2,80(sp)
    80006756:	69a6                	ld	s3,72(sp)
    80006758:	6a06                	ld	s4,64(sp)
    8000675a:	7ae2                	ld	s5,56(sp)
    8000675c:	7b42                	ld	s6,48(sp)
    8000675e:	7ba2                	ld	s7,40(sp)
    80006760:	7c02                	ld	s8,32(sp)
    80006762:	6ce2                	ld	s9,24(sp)
    80006764:	6d42                	ld	s10,16(sp)
    80006766:	6165                	addi	sp,sp,112
    80006768:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000676a:	0002b697          	auipc	a3,0x2b
    8000676e:	8966b683          	ld	a3,-1898(a3) # 80031000 <disk+0x2000>
    80006772:	96ba                	add	a3,a3,a4
    80006774:	4609                	li	a2,2
    80006776:	00c69623          	sh	a2,12(a3)
    8000677a:	b5c9                	j	8000663c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000677c:	f9042583          	lw	a1,-112(s0)
    80006780:	20058793          	addi	a5,a1,512
    80006784:	0792                	slli	a5,a5,0x4
    80006786:	00029517          	auipc	a0,0x29
    8000678a:	92250513          	addi	a0,a0,-1758 # 8002f0a8 <disk+0xa8>
    8000678e:	953e                	add	a0,a0,a5
  if(write)
    80006790:	e20d11e3          	bnez	s10,800065b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006794:	20058713          	addi	a4,a1,512
    80006798:	00471693          	slli	a3,a4,0x4
    8000679c:	00029717          	auipc	a4,0x29
    800067a0:	86470713          	addi	a4,a4,-1948 # 8002f000 <disk>
    800067a4:	9736                	add	a4,a4,a3
    800067a6:	0a072423          	sw	zero,168(a4)
    800067aa:	b505                	j	800065ca <virtio_disk_rw+0xf4>

00000000800067ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067ac:	1101                	addi	sp,sp,-32
    800067ae:	ec06                	sd	ra,24(sp)
    800067b0:	e822                	sd	s0,16(sp)
    800067b2:	e426                	sd	s1,8(sp)
    800067b4:	e04a                	sd	s2,0(sp)
    800067b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067b8:	0002b517          	auipc	a0,0x2b
    800067bc:	97050513          	addi	a0,a0,-1680 # 80031128 <disk+0x2128>
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	416080e7          	jalr	1046(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067c8:	10001737          	lui	a4,0x10001
    800067cc:	533c                	lw	a5,96(a4)
    800067ce:	8b8d                	andi	a5,a5,3
    800067d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067d6:	0002b797          	auipc	a5,0x2b
    800067da:	82a78793          	addi	a5,a5,-2006 # 80031000 <disk+0x2000>
    800067de:	6b94                	ld	a3,16(a5)
    800067e0:	0207d703          	lhu	a4,32(a5)
    800067e4:	0026d783          	lhu	a5,2(a3)
    800067e8:	06f70163          	beq	a4,a5,8000684a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067ec:	00029917          	auipc	s2,0x29
    800067f0:	81490913          	addi	s2,s2,-2028 # 8002f000 <disk>
    800067f4:	0002b497          	auipc	s1,0x2b
    800067f8:	80c48493          	addi	s1,s1,-2036 # 80031000 <disk+0x2000>
    __sync_synchronize();
    800067fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006800:	6898                	ld	a4,16(s1)
    80006802:	0204d783          	lhu	a5,32(s1)
    80006806:	8b9d                	andi	a5,a5,7
    80006808:	078e                	slli	a5,a5,0x3
    8000680a:	97ba                	add	a5,a5,a4
    8000680c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000680e:	20078713          	addi	a4,a5,512
    80006812:	0712                	slli	a4,a4,0x4
    80006814:	974a                	add	a4,a4,s2
    80006816:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000681a:	e731                	bnez	a4,80006866 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000681c:	20078793          	addi	a5,a5,512
    80006820:	0792                	slli	a5,a5,0x4
    80006822:	97ca                	add	a5,a5,s2
    80006824:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006826:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000682a:	ffffc097          	auipc	ra,0xffffc
    8000682e:	ca6080e7          	jalr	-858(ra) # 800024d0 <wakeup>

    disk.used_idx += 1;
    80006832:	0204d783          	lhu	a5,32(s1)
    80006836:	2785                	addiw	a5,a5,1
    80006838:	17c2                	slli	a5,a5,0x30
    8000683a:	93c1                	srli	a5,a5,0x30
    8000683c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006840:	6898                	ld	a4,16(s1)
    80006842:	00275703          	lhu	a4,2(a4)
    80006846:	faf71be3          	bne	a4,a5,800067fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000684a:	0002b517          	auipc	a0,0x2b
    8000684e:	8de50513          	addi	a0,a0,-1826 # 80031128 <disk+0x2128>
    80006852:	ffffa097          	auipc	ra,0xffffa
    80006856:	438080e7          	jalr	1080(ra) # 80000c8a <release>
}
    8000685a:	60e2                	ld	ra,24(sp)
    8000685c:	6442                	ld	s0,16(sp)
    8000685e:	64a2                	ld	s1,8(sp)
    80006860:	6902                	ld	s2,0(sp)
    80006862:	6105                	addi	sp,sp,32
    80006864:	8082                	ret
      panic("virtio_disk_intr status");
    80006866:	00002517          	auipc	a0,0x2
    8000686a:	08250513          	addi	a0,a0,130 # 800088e8 <syscalls+0x468>
    8000686e:	ffffa097          	auipc	ra,0xffffa
    80006872:	cc2080e7          	jalr	-830(ra) # 80000530 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
