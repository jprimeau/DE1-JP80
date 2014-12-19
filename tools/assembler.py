#!/usr/bin/python

from grammar import grammar
import re

instructions = grammar.keys()

num = 1
address = 0
label_dict = {}

f = open('test.asm', 'r')
for line in f:
    opcode = ''
    label = ''
    mnemonic = ''
    destination = ''
    source = ''
    comment = ''
    dline = {}

    # Check and extract a label
    r = re.split(':?\s', line)
    if r and r[0] != '' and r[0][0] != ';':
        label = r[0]
    dline['label'] = label

    # Check and extract a comment
    r = re.search(';.*$', line)
    if r:
        comment = r.group(0)
    dline['comment'] = comment

    # Remove comments
    cline = re.sub(';.*$', '\r\n', line)
    # Remove trailing spaces
    cline = re.sub('\s*$', '\r\n', cline)
    for inst in instructions:
        match = re.search('\s'+inst+'\s', cline)
        if match:
            op = grammar[inst]
            optype = op[0]
            opsize = int(op[1])
            tmp_opcode = op[2]
            if optype == "R,D":
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search('\s*'+reg+'\s*,', cline)
                    if match:
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'R,R':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search('\s*'+reg+'\s*', cline)
                    if match:
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'Rp':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search('\s*'+reg+'\s*', cline)
                    if match:
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'R':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search('\s*'+reg+'\s*', cline)
                    if match:
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'P':
                match = re.search('\s+([0-9A-Fa-f]+)', cline)
                if match:
                    mnemonic = inst
                    opcode = tmp_opcode
                    address += opsize
                    break
            elif optype == 'A':
                match = re.search('\s+([0-9A-Fa-f]{1,2})', cline)
                if match:
                    mnemonic = inst
                    opcode = tmp_opcode
                    address += opsize
                    break
                match = re.search('\s+([0-9A-Fa-f]*)', cline)
                if match:
                    mnemonic = inst
                    opcode = tmp_opcode
                    address += opsize
                    break
            elif optype == 'D':
                match = re.search('\s+([0-9A-Fa-f]+)', cline)
                if match:
                    mnemonic = inst
                    opcode = tmp_opcode
                    address += opsize
                    break
            elif optype == '':
                mnemonic = inst
                opcode = tmp_opcode
                address += opsize
            break
    
    dline['mnemonic'] = mnemonic
    dline['destination'] = destination
    dline['source'] = source
    dline['opcode'] = opcode
    dline['address'] = "%04X"%address

    dline['line'] = "%05d"%num
    num += 1

    if label != '':
        label_dict[label] = "%04X"%address

    #print dline
    print dline['line'],dline['address'],dline['opcode']
print label_dict

