==============================================================
Experimental support for additional DWARF operations in SPIR-V
==============================================================

.. contents::
   :local:

Overview
========

Debug information in SPIR-V can be represented using `OpenCL.DebugInfo.100`_
extended instruction set, but unfortunately, this instruction set doesn' support
all functionality which can be represented with `DWARF4`_ and `DWARF5`_
standards.

In particular, not all DWARF operations are supported by OpenCL.DebugInfo.100:
DWARF5 contains ~160 different operations (based on table 7.9 DWARF operation
encodings), while OpenCL.DebugInfo.100 documents only 9 such operations (based
on a table from section `3.6 Debug Operations`_).

As an experimental feature, the translator supports major part of DWARF
operations from DWARF5 by extending the table from section
*3.6 Debug Operations* of `OpenCL.DebugInfo.100`_ extended instruction set.

**Important note**: This is not a formal specification and SPIR-V generated with
this experimental feature is not compliant with OpenCL.DebugInfo.100 extended
instruction set and therefore is not portable. This functionality is intended to
provide early access to the feature for review and community feedback. It is not
intended to be used by shipping software products.

.. _OpenCL.DebugInfo.100: https://www.khronos.org/registry/spir-v/specs/unified1/OpenCL.DebugInfo.100.html
.. _DWARF4: http://dwarfstd.org/doc/DWARF4.pdf
.. _DWARF5: http://www.dwarfstd.org/doc/DWARF5.pdf
.. _3.6 Debug Operations: https://www.khronos.org/registry/spir-v/specs/unified1/OpenCL.DebugInfo.100.html#_debug_operations_a_id_operation_a

How to use this functionality
=============================

As this functionality is not documented by any formal SPIR-V extension or SPIR-V
exteneded insturction set specification, it is disabled by default and in order
to enable generation of extra debug information, user need to pass
`-spirv-with-experimental-debug-operations` command line option to the
translator.

List of new DWARF operations supported
======================================

The table below extends the table in section 3.6 *Debug Operations*
of `OpenCL.DebugInfo.100`_ Extended Instruction Set.

+-----+------------------------+------------------+------------------------------------------------------------------+
|  Operation encodings         |  No. of Operands | Description                                                      |
+=====+========================+==================+==================================================================+
| 10  |     *Convert*          |  2               | Pops the top stack entry, converts it to a different type,       |
|     |                        |                  | then pushes the result. Takes two single word Literal operands,  |
|     |                        |                  | that specify bit size and encoding of the destination conversion |
|     |                        |                  | type.                                                            |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 11  |     *Addr*             |  1               | Reserved for corresponding operations from DWARF5                |
|     |                        |                  | specification, but unsupported at the moment.                    |
+-----+------------------------+------------------+                                                                  +
| 12  |     *Const1u*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 13  |     *Const1s*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 14  |     *Const2u*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 15  |     *Const2s*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 16  |     *Const4u*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 17  |     *Const4s*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 18  |     *Const8u*          |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 19  |     *Const8s*          |  1               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 20  |     *Consts*           |  1               | Pushes a constant value onto the stack. The value operand        |
|     |                        |                  | must be a single word signed integer literal.                    |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 21  |    *Dup*               |  0               | Duplicates the value at the top of the stack.                    |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 22  |    *Drop*              |  0               | Pops the value at the top of the stack.                          |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 23  |    *Over*              |  0               | Duplicate the entry currently second in the stack at             |
|     |                        |                  | the top of the stack. This is equivalent to *Pick*               |
|     |                        |                  | operaiton with index 1.                                          |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 24  |    *Pick*              |  1               | Pushes a copy of the stack entry with the specified 1-byte       |
|     |                        |                  | index (0 through 255, inclusive) back onto stack.                |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 25  |    *Rot*               |  0               | Rotates the first three stack entries. The entry at              |
|     |                        |                  | the top of the stack becomes the third stack entry, the          |
|     |                        |                  | second entry becomes the top of the stack, and the third         |
|     |                        |                  | entry becomes the second entry.                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 26  |    *Abs*               |  0               | Pops the top stack entry, interprets it as a signed              |
|     |                        |                  | value and pushes its absolute value. If the absolute             |
|     |                        |                  | value cannot be represented, the result is undefined.            |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 27  |    *And*               |  0               | Pops the top two stack values, performs a bitwise                |
|     |                        |                  | and operation on the two, and pushes the restul.                 |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 28  |    *Div*               |  0               | Pops the top two stack values, divides the former                |
|     |                        |                  | second entry by the former top of the stack using                |
|     |                        |                  | division, and pushes the result.                                 |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 29  |    *Mod*               |  0               | Pops the top two stack values and pushes the result              |
|     |                        |                  | of the calculation: former second stack entry modulo             |
|     |                        |                  | the former top of the stack.                                     |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 30  |    *Mul*               |  0               | Pops the top two stack entries, multiplies them                  |
|     |                        |                  | together, and pushes the result.                                 |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 31  |    *Neg*               |  0               | Pops the top stack entry, interprets it as a signed              |
|     |                        |                  | value and pushes its negation. If the negation                   |
|     |                        |                  | cannot be represented, the result is undefined.                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 32  |    *Not*               |  0               | Pops the top stack entry, and pushes its bitwise                 |
|     |                        |                  | complement.                                                      |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 33  |    *Or*                |  0               | Pops the two stack entries, performs a bitwise or                |
|     |                        |                  | operation on the two, and pushes the result.                     |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 34  |    *Shl*               |  0               | Pops the top two stack entries, shifts the former                |
|     |                        |                  | second entry left (filling with zero bits) by the                |
|     |                        |                  | number of bits specified by the former top of the                |
|     |                        |                  | stack, and pushes the result.                                    |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 35  |    *Shr*               |  0               | Pops the top two stack entries, shifts the former                |
|     |                        |                  | second entry right logically (filling with zero bits)            |
|     |                        |                  | by the number of bits specified by the formper top of            |
|     |                        |                  | the stack, and pushes the result.                                |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 36  |    *Shra*              |  0               | Pops the top two stack entries, shifts the former                |
|     |                        |                  | second entry right arithmetically (divide the                    |
|     |                        |                  | magnitude by 2, keep the same sign for the result)               |
|     |                        |                  | by the number of bits specified by the former top                |
|     |                        |                  | of the stack, and pushes the result.                             |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 37  |    *Xor*               |  0               | Pops the top two stack entries, performs a bitwise               |
|     |                        |                  | exclusive-or operation on the two, and pushes the result.        |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 38  |    *Bra*               |  1               | Reserved for corresponding operation from DWARF5 spec, but       |
|     |                        |                  | unsupported at the moment.                                       |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 39  |    *Eq*                |  0               | Six relational operators each:                                   |
|     |                        |                  |                                                                  |
|     |                        |                  | - pop the two stack values, which have the same type             |
|     |                        |                  | - compare the operands:                                          |
|     |                        |                  |   <former second enrty> <relational operator> <former top entry> |
|     |                        |                  | - push the constant value 1 onto the stack if the result of the  |
|     |                        |                  |   operation is true or the constant value 0 if the result of the |
|     |                        |                  |   operation is false.                                            |
+-----+------------------------+------------------+                                                                  +
| 40  |    *Ge*                |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 41  |    *Gt*                |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 42  |    *Le*                |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 43  |    *Lt*                |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 44  |    *Ne*                |  0               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 45  |    *Skip*              |  1               | Reserved for corresponding operation from DWARF5 spec, but       |
|     |                        |                  | unsupported at the moment.                                       |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 46  |    *Lit0*              |  0               | The Lit<n> operations encode the unsigned literal values from 0  |
|     |                        |                  | through 31, inclusive.                                           |
+-----+------------------------+------------------+                                                                  +
| 47  |    *Lit1*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 48  |    *Lit2*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 49  |    *Lit3*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 50  |    *Lit4*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 51  |    *Lit5*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 52  |    *Lit6*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 53  |    *Lit7*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 54  |    *Lit8*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 55  |    *Lit9*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 56  |    *Lit10*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 57  |    *Lit11*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 58  |    *Lit12*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 59  |    *Lit13*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 60  |    *Lit14*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 61  |    *Lit15*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 62  |    *Lit16*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 63  |    *Lit17*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 64  |    *Lit18*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 65  |    *Lit19*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 66  |    *Lit20*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 67  |    *Lit21*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 68  |    *Lit22*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 69  |    *Lit23*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 70  |    *Lit24*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 71  |    *Lit25*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 72  |    *Lit26*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 73  |    *Lit27*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 74  |    *Lit28*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 75  |    *Lit29*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 76  |    *Lit30*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 77  |    *Lit31*             |  0               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 78  |    *Reg0*              |  0               | *Reg<n>* operation encode the names of up to 32 registers,       |
|     |                        |                  | numbered from 0 through 31, inclusive. The object addressed is   |
|     |                        |                  | in register n.                                                   |
+-----+------------------------+------------------+                                                                  +
| 79  |    *Reg1*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 80  |    *Reg2*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 81  |    *Reg3*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 82  |    *Reg4*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 83  |    *Reg5*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 84  |    *Reg6*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 85  |    *Reg7*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 86  |    *Reg8*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 87  |    *Reg9*              |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 88  |    *Reg10*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 89  |    *Reg11*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 90  |    *Reg12*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 91  |    *Reg13*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 92  |    *Reg14*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 93  |    *Reg15*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 94  |    *Reg16*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 95  |    *Reg17*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 96  |    *Reg18*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 97  |    *Reg19*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 98  |    *Reg20*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 99  |    *Reg21*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 100 |    *Reg22*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 101 |    *Reg23*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 102 |    *Reg24*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 103 |    *Reg25*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 104 |    *Reg26*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 105 |    *Reg27*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 106 |    *Reg28*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 107 |    *Reg29*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 108 |    *Reg30*             |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 109 |    *Reg31*             |  0               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 110 |    *Breg0*             |  1               | Breg<n> operation provides a signed offset from the contents of  |
|     |                        |                  | the specified register. Operand is a single word signed interger |
|     |                        |                  | literal                                                          |
+-----+------------------------+------------------+                                                                  +
| 111 |    *Breg1*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 112 |    *Breg2*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 113 |    *Breg3*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 114 |    *Breg4*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 115 |    *Breg5*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 116 |    *Breg6*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 117 |    *Breg7*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 118 |    *Breg8*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 119 |    *Breg9*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 120 |    *Breg10*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 121 |    *Breg11*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 122 |    *Breg12*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 123 |    *Breg13*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 124 |    *Breg14*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 125 |    *Breg15*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 126 |    *Breg16*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 127 |    *Breg17*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 128 |    *Breg18*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 129 |    *Breg19*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 130 |    *Breg20*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 131 |    *Breg21*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 132 |    *Breg22*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 133 |    *Breg23*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 134 |    *Breg24*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 135 |    *Breg25*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 136 |    *Breg26*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 137 |    *Breg27*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 138 |    *Breg28*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 139 |    *Breg29*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 140 |    *Breg30*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 141 |    *Breg31*            |  1               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 142 |    *Regx*              |  1               | Encodes the name of a register as a single word unsigned integer.|
+-----+------------------------+------------------+------------------------------------------------------------------+
| 143 |    *Fbreg*             |  1               | Reserved for corresponding operation from DWARF5 spec, but       |
|     |                        |                  | unsupported at the moment.                                       |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 144 |    *Bregx*             |  2               | Provides the sum of two values specified by its two operands.    |
|     |                        |                  | The first operand is a register number which is specified by a   |
|     |                        |                  | single word unsigned integer literal. The second operand is      |
|     |                        |                  | offset represented as a single word signed integer literal.      |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 145 |    *Piece*             |  1               | Reserved for corresponding operation from DWARF5 spec, but       |
|     |                        |                  | unsupported at the moment.                                       |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 146 |    *DerefSize*         |  1               | Behaves like *Deref* operaiton: it pops the top stack            |
|     |                        |                  | entry and treats it as an address. The popped value must         |
|     |                        |                  | have an integral type. The value retrieved from that             |
|     |                        |                  | address is pushed, and has the generic type. In the              |
|     |                        |                  | *DerefSize* operation, however, the size in bytes                |
|     |                        |                  | of the data retrieved from the dereferenced address is           |
|     |                        |                  | specified by the single operand. This operand is a single        |
|     |                        |                  | word unsigned integral constant whose value may not              |
|     |                        |                  | be larger than the size of the generic type. The data            |
|     |                        |                  | retrieved is zero extended to the size of an address             |
|     |                        |                  | on the target machine before being pushed onto the               |
|     |                        |                  | expression stack.                                                |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 147 |    *XDerefSize*        |  1               | Behaves like the *XDeref* operation. The entry at                |
|     |                        |                  | the top of the stack is treated as an address. The second        |
|     |                        |                  | stack entry is treated as an ddress space identifier             |
|     |                        |                  | Both of these entries must have integral type                    |
|     |                        |                  | identifiers. The top two stack elements are popped, and a        |
|     |                        |                  | data item is retrieved through an implementation-defined         |
|     |                        |                  | address calculation and pushed as the new stack top.             |
|     |                        |                  | In the *XDerefSize* operation, however, the size                 |
|     |                        |                  | in bytes of the data retrieved from the dereferenced             |
|     |                        |                  | address is specified by the single operand. This operand         |
|     |                        |                  | is a single word unsigned integral constant whose value may      |
|     |                        |                  | not be larger than the size of an address on the target          |
|     |                        |                  | machine. The data retrieved is zero extended to the size         |
|     |                        |                  | of an address on the target machine before being pushed          |
|     |                        |                  | onto the expression stack together with the generic type         |
|     |                        |                  | identifier.                                                      |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 148 |    *Nop*               |  0               | Place holder. It has no effect on the location stack or          |
|     |                        |                  | any of its values.                                               |
+-----+------------------------+------------------+------------------------------------------------------------------+
| 149 |    *PushObjectAddress* |  0               | Reserved for corresponding operations from DWARF5 specification, |
|     |                        |                  | but unsupported at the moment.                                   |
+-----+------------------------+------------------+                                                                  +
| 150 |    *Call2*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 151 |    *Call4*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 152 |    *CallRef*           |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 153 |    *FormTlsAddress*    |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 154 |    *CallFrameCfa*      |  0               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 156 |    *ImplicitPointer*   |  2               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 157 |    *AddrX*             |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 158 |    *ConstX*            |  1               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 159 |    *EntryValue*        |  2               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 160 |    *ConstType*         |  3               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 161 |    *RegvalType*        |  2               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 162 |    *DerefType*         |  2               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 163 |    *XDerefType*        |  2               |                                                                  |
+-----+------------------------+------------------+                                                                  +
| 164 |    *Reinterpret*       |  1               |                                                                  |
+-----+------------------------+------------------+------------------------------------------------------------------+
