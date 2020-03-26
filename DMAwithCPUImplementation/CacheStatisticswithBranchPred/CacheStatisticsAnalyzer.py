f = open("ExecutionHist_Debug.txt", 'r')

history = f.read()

f.close()

historylines = history.split('\n')


def bintohex_noloss(bin_str):
	hex_digitnum = (len(bin_str) + 3) // 4
	if bin_str[-1]=='x':
		return ("0x" + "{:0>" + str(hex_digitnum) + "}").format('X'*hex_digitnum)
	elif bin_str[-1]=='z':
		return ("0x" + "{:0>" + str(hex_digitnum) + "}").format('Z'*hex_digitnum)

	hex_num = hex(int(bin_str, 2))
	return ("0x" + "{:0>" + str(hex_digitnum) + "}").format(hex_num[2:])


def tohex_noloss(dec_str):
	hex_digitnum = 4
	hex_num = hex(int(dec_str))
	return ("0x" + "{:0>" + str(hex_digitnum) + "}").format(hex_num[2:])


def reverse_assemble(bincode):
	opcode = bincode[0:4]
	if (opcode == "1111"):
		type = 'R'
	elif (opcode in ("1001", "1010")):
		type = 'J'
	else:
		type = 'I'

	rs = '$' + str(int(bincode[4:6], 2))
	rt = '$' + str(int(bincode[6:8], 2))
	rd = '$' + str(int(bincode[8:10], 2))

	if type is 'R':
		funct = int(bincode[10:], 2)
		functdict = {0: 'ADD', 1: 'SUB', 2: 'AND', 3: 'ORR', 4: 'NOT', 5: 'TCP', 6: 'SHL', 7: 'SHR', 28: 'WWD',
					 25: 'JPR', 26: 'JRL', 29: 'HLT'}

		inst = functdict[funct]

		if funct < 4:
			return "{} {} {} {}".format(inst, rd, rs, rt)
		elif funct < 8:
			return "{} {} {}".format(inst, rd, rs)
		elif funct < 29:
			return "{} {}".format(inst, rs)
		else:
			return "HLT"
	elif type is 'I':
		opcode = int(opcode, 2)
		opcodedict = {4: 'ADI', 5: 'ORI', 6: 'LHI', 7: 'LWD', 8: 'SWD', 0: 'BNE', 1: 'BEQ', 2: 'BGZ', 3: 'BLZ'}
		imm = bintohex_noloss(bincode[8:])

		if opcode not in ("LHI", "BGZ", "BLZ"):
			return "{} {} {} {}".format(opcodedict[opcode], rt, rs, imm)
		else:
			return "{} {} {}".format(opcodedict[opcode], rt, imm)
	else:
		opcode = int(opcode, 2)
		opcodedict = {9: 'JMP', 10: 'JAL'}
		jump_target = bintohex_noloss(bincode[4:])

		return "{} {}".format(opcodedict[opcode], jump_target)


for k in range(len(historylines) - 1, -1, -1):
	historylines[k] = historylines[k].split()
	if not len(historylines[k]):
		del historylines[k]
		continue
	historylines[k][0] = tohex_noloss(historylines[k][0])
	historylines[k][1] = reverse_assemble(historylines[k][1])
	historylines[k][2] = bintohex_noloss(historylines[k][2])
	historylines[k][3] = bintohex_noloss(historylines[k][3])
	historylines[k][4] = bintohex_noloss(historylines[k][4])
	historylines[k][7] = bintohex_noloss(historylines[k][7])

for line in historylines:
	print("{:6} {:<20} {:6} {:6} {:6} {:1} {:1} {:6} {:1} {:1}".format(*line))

# for line in historylines:
#    if(line[1][:3]=='HLT'):
#        print("{:4} {:<20} {:6} {:6}".format(*line))

# 981 HLT                  0x00ad 0x00ae

HLTNO = len(historylines) - 1
for k in range(len(historylines)):
	if(historylines[k][1][:3]=='HLT'):
		HLTNO = k
		break

# Branch Prediction Statistics Analysis
Control_Instruction = ("JMP", "JAL", "JPR", "JRL", "BEQ", "BNE", "BGZ", "BLZ")

branchhitmiss = [
	[k, historylines[k][1], historylines[k][3] == historylines[k + 1][2], historylines[k][3], historylines[k + 1][2]]
	for k in range(HLTNO) if historylines[k][1][:3] in Control_Instruction]
nonbranchhitmiss = [
	[k, historylines[k][1], historylines[k][3] == historylines[k + 1][2], historylines[k][3], historylines[k + 1][2]]
	for k in range(HLTNO) if historylines[k][1][:3] not in Control_Instruction]

branchhitmiss_summary = {"hit": 0, "miss": 0}
for history in branchhitmiss:
	if history[2]:
		branchhitmiss_summary["hit"] += 1
	else:
		branchhitmiss_summary["miss"] += 1

nonbranchhitmiss_summary = {"hit": 0, "miss": 0}
for history in nonbranchhitmiss:
	if history[2]:
		nonbranchhitmiss_summary["hit"] += 1
	else:
		nonbranchhitmiss_summary["miss"] += 1

print(branchhitmiss_summary)
print(nonbranchhitmiss_summary)
print('Accuracy of branch instruction prediction:',
	  branchhitmiss_summary["hit"] / sum(branchhitmiss_summary.values()))

# Cache Hit/Miss Analysis
I_cachehitmiss = [
	[historylines[k][0], historylines[k][1], historylines[k][4],( historylines[k][6]=='H' if historylines[k][5] in ('R','W') else None), historylines[k][5]]
	for k in range(HLTNO)]

D_cachehitmiss = [
	[historylines[k][0], historylines[k][1], historylines[k][7],( historylines[k][9]=='H' if historylines[k][8] in ('R','W') else None), historylines[k][8]]
	for k in range(HLTNO)]

I_cachehitmiss_summary = {"R": {"hit": 0, "miss": 0}, "W": {"hit": 0, "miss": 0}, "X": 0}
for record in I_cachehitmiss:
	if record[4]=='X':
		I_cachehitmiss_summary['X'] += 1
	else:
		I_cachehitmiss_summary[record[4]][("hit" if record[3] else "miss")] += 1

print(I_cachehitmiss_summary)
A = I_cachehitmiss_summary
print("hit rate on instruction read:",A['R']["hit"]/sum(A['R'].values()))

D_cachehitmiss_summary = {"R": {"hit": 0, "miss": 0}, "W": {"hit": 0, "miss": 0}, "X": 0}
for record in D_cachehitmiss:
	if record[4]=='X':
		D_cachehitmiss_summary['X'] += 1
	else:
		D_cachehitmiss_summary[record[4]][("hit" if record[3] else "miss")] += 1

print(D_cachehitmiss_summary)
A=D_cachehitmiss_summary
print("hit rate on data read:",A['R']["hit"]/sum(A['R'].values()))
print("hit rate on data write:",A['W']["hit"]/sum(A['W'].values()))
print("total hit rate:",(A['R']["hit"]+A['W']["hit"])/(sum(A['R'].values())+sum(A['W'].values())))

#for record in D_cachehitmiss:
#	if record[3] != None:
#		print(record)
