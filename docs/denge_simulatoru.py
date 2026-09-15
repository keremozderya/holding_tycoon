# Dart'a yazilan Balance formullerini birebir yeniden uygulayip dogrula
import math
UNLOCK=[0,30,60,90,120]
INC_G=1.12; MS_STEP=10; MS_MULT=2.0; RATIO=12.0; PASSIVE=0.20; STEP=2.5; MAXL=60
CG1,CG2,CG3=1.339,1.299,1.259
FAC_INC_K=30.0; FAC_PRICE_K=12000.0; STARTER=2.0
OFF_EFF=0.25; OFF_CAP=8

def ms(l): return MS_MULT**(l//MS_STEP)
def upgrade_cost(base,l):
    t1=min(max(l,0),30); t2=min(max(l-30,0),15); t3=min(max(l-45,0),15)
    return base*CG1**t1*CG2**t2*CG3**t3
def manual(base,l): return 0.0 if l==0 else base*INC_G**(l-1)*ms(l)
def tier(n): return 0 if n<=3 else n-3
def fbase(n): return STARTER*FAC_INC_K**tier(n)
def fprice(n): return 300000.0 if n<=3 else fbase(n)*RATIO*FAC_PRICE_K

def build():
    f=[]
    for n in range(1,16):
        b=fbase(n)
        f.append({'n':n,'b':b,'price':0.0 if n==1 else fprice(n),
                  'u':n==1,'lvl':[1,0,0,0,0] if n==1 else [0,0,0,0,0]})
    return f
def pinc(f,i,l=None):
    l=f['lvl'][i] if l is None else l
    return manual(f['b']*STEP**i,l)
def pcost(f,i):
    l=f['lvl'][i]
    if l>=MAXL: return None
    if l==0 and sum(f['lvl'])<UNLOCK[i]: return None
    return upgrade_cost(f['b']*STEP**i*RATIO,l)
def ips(fs): return sum(pinc(f,i)*PASSIVE for f in fs if f['u'] for i in range(5))

def run(active_min=30,tpm=45,days=200):
    fs=build(); money=turn=0.0; curve=[]
    for d in range(1,days+1):
        g=ips(fs)*OFF_CAP*3600*OFF_EFF; money+=g; turn+=g
        tick=max(1,int(60/tpm))
        for sec in range(active_min*60):
            g=ips(fs); money+=g; turn+=g
            if sec%tick==0:
                b=max([pinc(f,i) for f in fs if f['u'] for i in range(5)]+[0.0])
                money+=b; turn+=b
            for _ in range(60):
                bv=0; ba=None
                for f in fs:
                    if not f['u']:
                        if f['price']<=money:
                            v=(f['b']*PASSIVE)/max(f['price'],1)
                            if v>bv: bv,ba=v,('u',f,None)
                        continue
                    for i in range(5):
                        c=pcost(f,i)
                        if c is None or c>money: continue
                        v=((pinc(f,i,f['lvl'][i]+1)-pinc(f,i))*PASSIVE)/c
                        if v>bv: bv,ba=v,('p',f,i)
                if ba is None: break
                k,f,i=ba
                if k=='u': money-=f['price']; f['u']=True; f['lvl'][0]=1
                else: money-=pcost(f,i); f['lvl'][i]+=1
        tl=sum(sum(f['lvl']) for f in fs); nf=sum(1 for f in fs if f['u'])
        curve.append((d,ips(fs),turn,nf,tl))
        if nf==15 and tl>=4500: return d,curve
    return None,curve

d,c=run()
print(f"DART'A YAZILAN FORMÜLLERLE BİTİŞ GÜNÜ: {d}\n")
print(f"{'gün':>4} {'gelir/sn':>11} {'ciro':>11} {'fab':>4} {'lvl':>6}")
for r in c:
    if r[0]%10==0 or r[0] in (1,d): print(f"{r[0]:>4} {r[1]:>11.2e} {r[2]:>11.2e} {r[3]:>4} {r[4]:>6}")
print("\n--- süre hassasiyeti ---")
for m in (15,20,30,45,60):
    dd,_=run(active_min=m); print(f"  {m:>2} dk/gün -> {dd} gün")
print("\n--- prestij RP kontrolü (ağaç toplamı 3932 RP) ---")
for day,t in [(50,None),(60,None),(70,None),(80,None),(88,None)]:
    tv=[r[2] for r in c if r[0]==day]
    if tv: print(f"  {day}. gün ciro {tv[0]:.2e} -> prestij {int(12*(tv[0]/1e20)**0.30)} RP")
