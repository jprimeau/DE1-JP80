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

f = open('cpu_self_test.asm', 'r')

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
    lo = ''
    hi = ''
    m = re.search('[0-9A-Fa-f]{1,4}(h|H)?', operand)
    if m:
        if operand[-1:] == 'h' or operand[-1:] == 'H':
            operand = operand[:-1]
        if vtype == 'D':
            tmp = "%02X" % int(operand, 16)
            lo = tmp[0:2]
        elif vtype == 'DD':
            tmp = "%04X" % int(operand, 16)
            lo = tmp[0:2]
            hi = tmp[2:4]
        elif vtype == 'A':
            tmp = "%04X" % int(operand, 16)
            lo = tmp[2:4]
            hi = tmp[0:2]        
    return (lo,hi)

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
                (byte_lo,byte_hi) = ExtractOperandValue(t_operand, t_type)
        elif mtype == "AD":
            operand = re.sub('^\s*', '', line)
            operand = re.sub('\s*$', '', operand)
            if mnemonic == 'org':
                lo = hi = 0
                (lo,hi) = ExtractOperandValue(operand, 'DD')
                org = int(lo+hi, 16)
            elif mnemonic == 'defw':
                pass

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

byte_array = ['FF']*256
idx = 0
for dline in dlines:
    # Replace label in operand by value
    label = re.sub('.*,\s*', '', dline['operand'])
    if label in labels:
        if dline['type'] == 'A':
            dline['bytes'].append(labels[label][2:4])
            dline['bytes'].append(labels[label][0:2])
        elif dline['type'] == 'D' or dline['type'] == 'P' or dline['type'] == 'R,D':
            dline['bytes'].append(labels[label][0:2])
        elif dline['type'] == 'Rp,DD':

            dline['bytes'].append(labels[label][0:2])
            dline['bytes'].append(labels[label][2:4])
    for byte in dline['bytes']:
        byte_array[idx] = byte
        idx += 1
    print "%4s"%dline['line'],
    print "%4s"%dline['address'],
    for byte in dline['bytes']:
        print "%2s"%byte,
    print ' '*3*(3-len(dline['bytes'])),
    label = ''
    if dline['label'] != '':
        label = dline['label']+':'
    print "%20s"%label,
    print "%-4s"%dline['mnemonic'],
    print "%-24s"%dline['operand'],
    print dline['comment']

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

#["%02X"%ord(c) for c in str]
