--!optimize 2
local Bn = {}
type Bn = {man: number, exp: number}
local ZERO = {man=0, exp=0}
ONE = {man=1, exp=0}
INF = {man=1, exp=math.huge}
NEGINF = {man=-1, exp=math.huge}
NAN = {man=0, exp=-math.huge}

function Bn.toStr(val: Bn): string
	if val == INF then return 'Inf' end
	if val == NEGINF then return '-Inf' end
	if val == NAN then return 'NaN' end
	if val == ZERO then return '0' end
	local exp = math.floor(val.exp)
	local man = 10^(val.exp-exp)
	return man..'e'..exp
end

function Bn.toNumber(val: Bn): number
	local x = val.man * 10^val.exp
	return x
end

function Bn.convert(val: any): Bn
	local t = type(val)
	if t == "table" then
		local man, exp = val.man or val[1], val.exp or val[2]
		if man ~= nil and exp ~= nil then
			return {man=man, exp=exp}
		end
		return ZERO
	end
	if t == "number" then
		if val == 0 then return ZERO end
		if val == math.huge then return INF end
		if val == -math.huge then return NEGINF end
		return {man = math.sign(val), exp = math.log10(math.abs(val))}
	end
	if t == "string" then
		if val == "0" then return ZERO end
		if val == "inf" then return INF end
		if val == "-inf" then return NEGINF end
		if val == "nan" then return NAN end
		local eIndex = val:find("e") or val:find("E")
		local man, exp
		if eIndex then
			man = tonumber(val:sub(1, eIndex-1))
			exp = tonumber(val:sub(eIndex+1))
		else
			man = tonumber(val)
			exp = 0
		end
		if not man then return ZERO end
		local absMan = math.abs(man)
		if absMan > 0 and absMan < 10 then
			return {man = 1, exp = exp + (man < 0 and 0 or 0) + math.log10(absMan)}
		else
			return {man = 1, exp = exp + math.log10(absMan)}
		end
	end

	return ZERO
end

function Bn.add(val1: any, val2: any): Bn
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	if val1 == ZERO then return val2 end
	if val2 == ZERO then return val1 end
	local m1, m2, e1, e2 = val1.man, val2.man, val1.exp, val2.exp
	if e1 > e2 then
		local diff = 10^(e2-e1)
		local res = math.log10(m1+m2*diff) + e1
		return {man=1, exp = res}
	end
	local diff = 10^(e1-e2)
	local res = math.log10(m2+m1*diff) + e2
	return {man=1, exp = res}
end

function Bn.sub(val1: any, val2: any): Bn
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	if val1 == ZERO then return val2 end
	if val2 == ZERO then return val1 end
	local m1, m2, e1, e2 = val1.man, val2.man, val1.exp, val2.exp
	if e1 > e2 then
		local diff = 10^(e2-e1)
		local res = math.log10(m1-m2*diff) + e1
		return {man=1,exp=res}
	end
	local diff = 10^(e1-e2)
	local res = math.log10(m2-m1*diff) + e1
	return {man=1,exp=res}
end

function Bn.mul(val1: any, val2: any): Bn
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	return {man=1,exp=val1.exp+val2.exp}
end

function Bn.div(val1:any, val2:any): Bn
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	return {man=1,exp=val1.exp-val2.exp}
end

function Bn.pow(val1: any, val2: any): Bn
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	return {man=1,exp=val1.exp*(val2.man*10^val2.exp)}
end

function Bn.pow10(val: any): Bn
	val = Bn.convert(val)
	return {man=1, exp = val.man * 10^val.exp}
end

function Bn.logn(val: any): Bn
	val = Bn.convert(val)
	local log = math.log10(math.abs(val.exp)/0.4342944819032518)
	return {man=math.sign(val.exp), exp = log}
end

function Bn.log10(val: any): Bn
	val = Bn.convert(val)
	local res = math.log10(val.man)+val.exp
	return {man=1, exp=math.log10(res)}
end

function Bn.log(val1: any, base): Bn
	val1 = Bn.convert(val1)
	base = base and Bn.toNumber(Bn.convert(base))
	if not base then
		return {man=math.sign(val1.exp), exp = math.log10(math.abs(val1.exp)/0.4342944819032518)}
	end
	return{man=math.sign(val1.exp),exp=math.log10(math.abs(val1.man)/math.log10(base))}
end

function Bn.cmp(val1: any, val2: any): number
	val1, val2 = Bn.convert(val1), Bn.convert(val2)
	if val1.exp ~= val2.exp then return val1.exp > val2.exp and 1 or -1 end
	if val1.man ~= val2.man then return val1.man > val2.man and 1 or -1 end
	return 0
end

function Bn.eq(val1: any, val2: any): boolean
	return Bn.cmp(val1, val2) == 0
end

function Bn.le(val1: any, val2: any): boolean
	return Bn.cmp(val1, val2) == -1
end

function Bn.leeq(val1: any, val2: any): boolean
	return Bn.cmp(val1, val2) ~= 1
end

function Bn.me(val1: any, val2: any): boolean
	return Bn.cmp(val1, val2) == 1
end

function Bn.meeq(val1: any, val2: any): boolean
	return Bn.cmp(val1, val2) ~= -1
end

function Bn.showDigits(val, digits: number?): number
	digits = digits or 2
	return math.floor(val*10^digits:: number) / 10^digits:: number
end

function Bn.AddComma(val): string
	val = Bn.toNumber(Bn.convert(val))
	local left, num, right = tostring(val):match('^([^%d]*%d)(%d*)(.-)$')
	num = num:reverse():gsub('(%d%d%d)', '%1,')
	return left .. num:reverse() .. right
end

function Bn.short(val, digits, canComma)
	canComma = canComma or false
	val = Bn.convert(val)
	if val == NAN then return "NaN" end
	if val == INF then return "inf" end
	if val == ZERO then return "0" end
	local man, exp = val.man, val.exp
	local sign = man < 0 and "-" or ""
	man = math.abs(man)
	local SNumber = exp
	local leftover = SNumber % 3
	local baseVal = man * 10^leftover
	SNumber = math.floor(SNumber / 3)

	local base = {"", "k", "m", "b"}
	if SNumber <= #base-1 then
		local numStr = Bn.showDigits(baseVal, digits)
		if canComma and SNumber == 0 then
			return Bn.AddComma(numStr)
		else
			return sign .. numStr .. base[SNumber+1]
		end
	end
	local txt = ""
	local FirBigNumOnes = {"", "U","D","T","Qd","Qn","Sx","Sp","Oc","No"}
	local SecondOnes = {"", "De","Vt","Tg","qg","Qg","sg","Sg","Og","Ng"}
	local ThirdOnes = {"", "Ce", "Du","Tr","Qa","Qi","Se","Si","Ot","Ni"}
	local function suffixpart(n)
		local Hundreds = math.floor(n/100)
		n = n % 100
		local Tens = math.floor(n/10)
		local Ones = n % 10
		txt = txt .. FirBigNumOnes[Ones+1] .. SecondOnes[Tens+1] .. ThirdOnes[Hundreds+1]
	end
	if SNumber < 1000 then
		suffixpart(SNumber)
		return sign .. Bn.showDigits(baseVal, digits) .. txt
	end
	local MultOnes = {"Mi","Mc","Na","Pi","Fm","At","Zp","Yc", "Xo", "Ve", "Me", "Due", "Tre", "Te", "Pt", "He", "Hp", "Oct", "En", "Ic", "Mei", "Dui", "Tri", "Teti", "Pti", "Hei", "Hp", "Oci", "Eni", "Tra","TeC","MTc","DTc","TrTc","TeTc","PeTc","HTc","HpT","OcT","EnT","TetC","MTetc","DTetc","TrTetc","TeTetc","PeTetc","HTetc","HpTetc","OcTetc","EnTetc","PcT","MPcT","DPcT","TPCt","TePCt","PePCt","HePCt","HpPct","OcPct","EnPct","HCt","MHcT","DHcT","THCt","TeHCt","PeHCt","HeHCt","HpHct","OcHct","EnHct","HpCt","MHpcT","DHpcT","THpCt","TeHpCt","PeHpCt","HeHpCt","HpHpct","OcHpct","EnHpct","OCt","MOcT","DOcT","TOCt","TeOCt","PeOCt","HeOCt","HpOct","OcOct","EnOct","Ent","MEnT","DEnT","TEnt","TeEnt","PeEnt","HeEnt","HpEnt","OcEnt","EnEnt","Hect", "MeHect"}
	for i=#MultOnes,1,-1 do
		if SNumber >= 10^(i*3) then
			suffixpart(math.floor(SNumber / 10^(i*3))-1)
			txt = txt .. MultOnes[i+1]
			SNumber = SNumber % 10^(i*3)
		end
	end
	return sign .. Bn.showDigits(baseVal, digits) .. txt
end

return Bn