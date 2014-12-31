#!/usr/bin/python

#
# JP-80 Assembler
#

from grammar import grammar
import re
import sys

mnemonics = grammar.keys()

num = 1
address = 0
labels = {}
dlines = []

f = open('monitor.asm', 'r')

def ExtractLabel(line):
    sc = re.split(';', line)
    if sc[0] != '':
        r = re.search('[A-Za-z0-9_]*:', line)
        if r:
            label = r.group(0)[:-1]
            return label
    return ''

def ExtractLabelCleanLine(line):
    label = ExtractLabel(line)
    # Remove label from line
    line = re.sub(label+':', '', line)
    # Remove leading spaces
    line = re.sub('^\s*', '', line)
    return (label,line)

def ExtractLabels(f):
    labels = {}
    f.seek(0)
    for line in f:
        label = ExtractLabel(line)
        if label != '':
            labels[label] = ''
    return labels

def ExtractComment(line):
    r = re.search(';.*$', line)
    if r:
        comment = r.group(0)
        return comment
    return ''

def ExtractCommentCleanLine(line):
    comment = ExtractComment(line)
    # Remove comment and spaces
    line = re.sub('\s*;.*$', '', line)
    return (comment, line)

def ExtractMnemonic(line, mnemonics):
    for mnemonic in mnemonics:
        m = re.match(mnemonic+'(\s|$|;)', line)
        if m:
            return mnemonic
    return ''

def ExtractMnemonicCleanLine(line, mnemonics):
    mnemonic = ExtractMnemonic(line, mnemonics)
    if mnemonic != '':
        pass
        # Remove mnemonic and spaces
        line = re.sub(mnemonic+'\s*', '', line)
        # Remove spaces
        #line = re.sub('^\s*', '', line)
    return (mnemonic,line)

def MnemonicInfo(mnemonic, grammar):
    info = grammar[mnemonic]
    mtype = info[0]
    msize = info[1]
    mcode = info[2]
    return (mcode,mtype,msize)

def ExtractOperandLabel(operand):
    for label in labels:
        m = re.search(label, operand)
        if m:
            return label
    return ''

def ExtractOperandRegister(operand, regs_dict):
    regs = regs_dict.keys()
    comma = ''
    for reg in regs:
        m = re.search(reg, operand)
        if m:
            mcode = regs_dict[reg]
            return (reg,mcode)
    return ('','')

def ExtractOperandValue(operand, vtype):
    hi = ''
    lo = ''
    m = re.search('[0-9][0-9A-Fa-f]{0,4}(h|H)?', operand)
    if m:
        if operand[-1:] == 'h' or operand[-1:] == 'H':
            operand = operand[:-1]
        if vtype == 'D':
            tmp = "%02X" % int(operand, 16)
            lo = tmp[0:2]
        elif vtype == 'DD' or vtype == 'A':
            tmp = "%04X" % int(operand, 16)
            hi = tmp[0:2]
            lo = tmp[2:4]
    return (hi,lo)

labels = ExtractLabels(f)

# Sarting over
f.seek(0)

for line in f:
    org = 0
    label = ''
    comment = ''
    mnemonic = ''
    mcode = ''
    mtype = ''
    msize = 0
    operand = ''
    byte_lo = ''
    byte_hi = ''
    bytes = []
    dline = {}

    (label,line) = ExtractLabelCleanLine(line)
    (comment,line) = ExtractCommentCleanLine(line)
    (mnemonic,line) = ExtractMnemonicCleanLine(line, mnemonics)
    if mnemonic != '':
        (mcode,mtype,msize) = MnemonicInfo(mnemonic, grammar)
        if mnemonic != "defm":
            operand = re.sub('\s*', '', line)
        else:
            operand = re.sub('^\s*', '', line)
            operand = re.sub('\s*$', '', operand)
        if mtype == 'R,R' or mtype == 'Rp' or mtype == 'R':
            (reg,mcode) = ExtractOperandRegister(operand, mcode)
        elif mtype == 'A' or mtype == 'D':
            lbl = ExtractOperandLabel(operand)
            if lbl == '':
                (byte_lo,byte_hi) = ExtractOperandValue(operand, mtype)
        elif mtype == "R,D" or mtype == 'Rp,DD':
            t_operand = re.split(',', operand)[0]
            (reg,mcode) = ExtractOperandRegister(t_operand, mcode)
            t_operand = re.sub(reg+',', '', operand)
            lbl = ExtractOperandLabel(t_operand)
            if lbl == '':
                t_type = re.split(',', mtype)[1]
                (byte_hi,byte_lo) = ExtractOperandValue(t_operand, t_type)
        elif mtype == "AD":
            if mnemonic == 'org':
                (hi,lo) = ExtractOperandValue(operand, 'DD')
                org = int(hi+lo, 16)
            elif mnemonic == 'defw':
                msize = len(re.split(',', operand)) * 2
            elif mnemonic == 'defm':
                quote = 0
                items = []
                item = ''
                for c in operand:
                    if c == '"':
                        quote = not quote
                        continue
                    if not quote and c == ',':
                        items.append(item)
                        item = ''
                        continue
                    item += c
                items.append(item)
                for item in items:
                    (hi,lo) = ExtractOperandValue(item, 'D')
                    if lo != '':
                        bytes.append(lo)                        
                    else:
                        bytes.extend(["%02X"%ord(c) for c in item])

    if mcode:
        bytes.append(mcode)
    if byte_lo:
        bytes.append(byte_lo)
    if byte_hi:
        bytes.append(byte_hi)

    dline['line'] = "%04d"%num
    dline['address'] = "%04X"%address
    dline['label'] = label
    dline['mnemonic'] = mnemonic
    dline['type'] = mtype
    dline['size'] = msize
    dline['operand'] = operand
    dline['bytes'] = bytes
    dline['comment'] = comment
    dlines.append(dline)

    if label != '':
        labels[label] = "%04X"%address
    
    num += 1
    if org == 0:
        address += msize
    else:
        address = org

#sys.exit(0)

def PrintListLine(line):
    print "%4s"%line['line'],
    print "%4s"%line['address'],
    for byte in line['bytes']:
        print "%2s"%byte,
    print ' '*3*(3-len(line['bytes'])),
    if not line['label'] and not line['mnemonic'] and line['comment']:
        print line['comment']
    else:
        label = ''
        if line['label'] != '':
            label = line['label']+':'
        print "%-20s"%label,
        print "%-4s"%line['mnemonic'],
        print "%-24s"%line['operand'],
        print line['comment']

byte_array = ['FF']*256
idx = 0
for dline in dlines:
    # Replace label in operand by value
    items = []
    if dline['mnemonic'] == 'defw':
        items = re.split(',', dline['operand'])
        for item in items:
            if item in labels:
                dline['bytes'].append(labels[item][2:4])
                dline['bytes'].append(labels[item][0:2])
            else:
                (lo,hi) = ExtractOperandValue(item, 'A')
                dline['bytes'].append(lo)
                dline['bytes'].append(hi)
    else:
        label = re.sub('.*,\s*', '', dline['operand'])
        if label in labels:
            if dline['type'] == 'A' or dline['type'] == 'Rp,DD':
                dline['bytes'].append(labels[label][2:4])
                dline['bytes'].append(labels[label][0:2])
            elif dline['type'] == 'D' or dline['type'] == 'R,D':
                dline['bytes'].append(labels[label][0:2])

    for byte in dline['bytes']:
        byte_array[idx] = byte
        idx += 1

    PrintListLine(dline)

# x"C3",x"18",x"00",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
num = 0
idx = 0
address = 0
line = ''
for byte in byte_array:
    idx += 1
    comma = ','
    if idx == 256:
        comma = ' '
    line += 'x"'+byte+'"'+comma
    if num == 7:
        print ' '*8+line,'--',"%04X"%address
        address += 8
        line = ''
        num = 0
    else:
        num += 1

