#!/usr/bin/python

from grammar import grammar
import re

instructions = grammar.keys()

num = 1
address = 0
labels = {}
dlines = []

f = open('test.asm', 'r')

for line in f:
    # Find and extract label
    r = re.split(':?\s', line)
    if r and r[0] != '' and r[0][0] != ';':
        label = r[0]
        labels[label] = ''

f.seek(0)

for line in f:
    label = ''
    mnemonic = ''
    dst_src = ''
    comment = ''
    opcode = ''
    byte_lo = ''
    byte_hi = ''
    dline = {}

    # Find and extract label
    r = re.split(':?\s', line)
    if r and r[0] != '' and r[0][0] != ';':
        label = r[0]
    dline['label'] = label
    # Remove label
    line = re.sub('^.*:', '', line)
    # Remove leading spaces
    line = re.sub('^\s*', '', line)

    # Find and extract comment
    r = re.search(';.*$', line)
    if r:
        comment = r.group(0)
    dline['comment'] = comment
    # Remove comment and spaces
    line = re.sub('\s*;.*$', '', line)

    for inst in instructions:
        match = re.match(inst+'(\s|$)', line)
        if match:
            # Remove mnemonic and spaces
            line = re.sub(match.group(0), '', line)
            # Remove spaces
            line = re.sub('\s*', '', line)
            op = grammar[inst]
            optype = op[0]
            opsize = int(op[1])
            tmp_opcode = op[2]
            t_dst_src = line
            if optype == "R,D":
                regs = tmp_opcode.keys()
                for reg in regs:
                    m_dst = re.match(reg+',', line)
                    if m_dst:
                        # Remove destination
                        line = re.sub(m_dst.group(0), '', line)
                        m_src = re.search('[0-9A-Fa-f]+(h|H)', line)
                        if m_src:
                            dst_src = t_dst_src
                            byte_lo = "%02X" % int(m_src.group(0)[:-1], 16)
                            mnemonic = inst
                            opcode = tmp_opcode[reg]
                            address += opsize
                        break
            elif optype == 'R,R':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search(reg, line)
                    if match:
                        dst_src = t_dst_src
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'Rp':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search(reg, line)
                    if match:
                        dst_src = t_dst_src
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'R':
                regs = tmp_opcode.keys()
                for reg in regs:
                    match = re.search(reg, line)
                    if match:
                        dst_src = t_dst_src
                        mnemonic = inst
                        opcode = tmp_opcode[reg]
                        address += opsize
                        break
            elif optype == 'P':
                match = re.search('[0-9A-Fa-f]+(h|H)?', line)
                if match:
                    dst_src = t_dst_src
                    byte_lo = "%02X" % int(match.group(0), 16)
                    mnemonic = inst
                    opcode = tmp_opcode
                    address += opsize
                    break
            elif optype == 'A':
                lbl_found = False
                for lbl in labels:
                    m_lbl = re.search(lbl, line)
                    if m_lbl:
                        dst_src = t_dst_src
                        lbl_found = True
                        mnemonic = inst
                        opcode = tmp_opcode
                        address += opsize
                        break
                if not lbl_found:
                    match = re.search('[0-9A-Fa-f]{1,2}(h|H)?', line)
                    if match:
                        dst_src = t_dst_src
                        tmp = "%04X" % int(match.group(0), 16)
                        byte_lo = tmp[2:4]
                        byte_hi = tmp[0:2]
                        mnemonic = inst
                        opcode = tmp_opcode
                        address += opsize
                        break
            elif optype == 'Rp,DD':
                regs = tmp_opcode.keys()
                for reg in regs:
                    m_dst = re.match(reg+',', line)
                    if m_dst:
                        # Remove destination
                        line = re.sub(m_dst.group(0), '', line)
                        lbl_found = False
                        for lbl in labels:
                            m_lbl = re.search(lbl, line)
                            if m_lbl:
                                lbl_found = True
                                dst_src = t_dst_src                                
                                mnemonic = inst
                                opcode = tmp_opcode[reg]
                                address += opsize
                                break
                        if not lbl_found:
                            match = re.search('[0-9A-Fa-f]{1,2}(h|H)?', line)
                            if match:
                                dst_src = t_dst_src
                                tmp = "%04X" % int(match.group(0), 16)
                                byte_lo = tmp[2:4]
                                byte_hi = tmp[0:2]
                                mnemonic = inst
                                opcode = tmp_opcode[reg]
                                address += opsize
                                break
                        break
            elif optype == 'D':
                match = re.search('[0-9A-Fa-f]+(h|H)?', line)
                if match:
                    dst_src = t_dst_src
                    byte_lo = "%02X" % int(match.group(0)[:-1], 16)
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
    dline['dst_src'] = dst_src
    dline['opcode'] = opcode
    dline['byte_lo'] = byte_lo
    dline['byte_hi'] = byte_hi
    dline['address'] = "%04X"%address
    dline['line'] = "%05d"%num
    num += 1

    if label != '':
        labels[label] = "%04X"%address
    dlines.append(dline)

byte_array = ['FF']*256
idx = 0
for dline in dlines:
    # Replace label in operand by value
    label = re.sub('.*,\s*', '', dline['dst_src'])
    if label in labels:
        dline['byte_lo'] = labels[label][2:4]
        dline['byte_hi'] = labels[label][0:2]
    if dline['opcode']:
        byte_array[idx] = dline['opcode']
        idx += 1
    if dline['byte_lo']:
        byte_array[idx] = dline['byte_lo']
        idx += 1
    if dline['byte_hi']:
        byte_array[idx] = dline['byte_hi']
        idx += 1
    print "%5s"%dline['line'],
    print "%4s"%dline['address'],
    print "%2s"%dline['opcode'],
    print "%2s"%dline['byte_lo'],
    print "%2s"%dline['byte_hi'],
    print "%20s"%dline['label'],
    print "%-4s"%dline['mnemonic'],
    print "%-24s"%dline['dst_src'],
    print dline['comment']
print labels
# x"C3",x"18",x"00",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
#num = 0
#for byte in byte_array:
#    if num == 7:
#        print 'x"'+byte+'",'
#        num = 0
#    else:
#        print 'x"'+byte+'",',
#        num += 1

