const {chromium}=require('playwright');
const OUT=require('path').resolve(__dirname,'../out')+'/'; require('fs').mkdirSync(OUT,{recursive:true}); const TAG=process.argv[2]||'fd', MODE=process.argv[3]||'smart', SHOTS=process.argv[4]!=='noshot', HORSE=process.argv[5]!=='nohorse';
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({viewport:{width:360,height:780},deviceScaleFactor:2,hasTouch:true});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push('PE '+e.message+' | '+(e.stack||'').split('\n').slice(1,3).join(' ')));p.on('console',m=>{if(m.type()==='error'&&!m.text().includes('ERR_TUNNEL'))errs.push(m.text().slice(0,300))});
await p.goto(require('url').pathToFileURL(require('path').resolve(__dirname,'../dist/index.html')).href);await p.waitForTimeout(1000);
await p.evaluate((h)=>{const M=window.__BW.wSV(); M.horse=h; M.intro=true; window.__BW.lobby();},HORSE);
await p.waitForTimeout(300); if(SHOTS) await p.screenshot({path:OUT+TAG+'_0lobby.png'});
await p.evaluate(()=>{window.__BW.startField();}); await p.waitForTimeout(600); if(SHOTS) await p.screenshot({path:OUT+TAG+'_1start.png'});
const stats=[]; const shotAt=[40,150,250]; let si=0;
for(let chunk=0;chunk<260;chunk++){
  const r=await p.evaluate((mode)=>{const B=window.__BW,K=B.keys; let picks=[];
    for(let i=0;i<150;i++){ const A=B.A; if(!A) return {gone:true,picks};
      if(A.state==='play' && A.musouT>1.2 && !window.__s1){window.__s1=1; return {st:'snap',nm:'musou',picks};}
      if(A.state==='play' && A.ride && A.en.filter(e=>Math.hypot(e.x-A.p.x,e.y-A.p.y)<120).length>=8 && !window.__s2 && A.t>20){window.__s2=1; return {st:'snap',nm:'ride',picks};}
      if(A.state==='play' && A.cbN>=60 && A.cb.i===0 && A.en.some(e=>e.air>0.2) && !window.__s3){window.__s3=1; return {st:'snap',nm:'combo',picks};}
      if(A.state==='play' && A.vil.st==='raid' && Math.hypot(A.vil.x-A.p.x,A.vil.y-A.p.y)<200 && !window.__s4){window.__s4=1; return {st:'snap',nm:'village',picks};}
      if(A.state==='play' && A.boss && Math.hypot(A.boss.x-A.p.x,A.boss.y-A.p.y)<220 && !window.__s5){window.__s5=1; return {st:'snap',nm:'boss',picks};}
      if(A.state==='play' && A.camps.some(c=>c.lead&&!c.cap&&Math.hypot(c.lead.x-A.p.x,c.lead.y-A.p.y)<160) && !window.__s6){window.__s6=1; return {st:'snap',nm:'leader',picks};}
      if(A.state==='pick' && !window.__s7 && document.querySelector('#ov:not([hidden]) [data-o]') && A.lvl>=6){window.__s7=1; return {st:'snap',nm:'levelup',picks};}
      if(A.state==='pick'){ const ok=document.querySelector('#ov:not([hidden]) #ok'); if(ok){picks.push('CHEST'); ok.click(); continue;}
        const os=[...document.querySelectorAll('#ov:not([hidden]) [data-o]')]; if(!os.length) return {st:'pick?',picks};
        let c=os[0]; if(mode==='rand') c=os[Math.floor(Math.random()*os.length)]; else { const ev=os.find(o=>o.classList.contains('evo')); const own=os.find(o=>!o.innerText.includes('새 기술')); c=ev||own||os[0]; }
        picks.push(c.innerText.split('\n')[0]); c.click(); continue; }
      if(A.state!=='play') return {st:A.state,t:A.t,picks};
      const pl=A.p, T=B.fieldTarget(mode==='nohome'), F=B.F1;
      // 길 찾기: 진영·본진은 남쪽 문으로, 관문은 가운데 문으로
      let wx=T.x, wy=T.y; const inW=B.insideWalls(pl);
      const camp=A.camps.find(c=>Math.abs(c.x-T.x)<1&&Math.abs(c.y-T.y)<1); const R=camp|| ((A.keepOpen&&!A.cyzOn)||A.boss? F.keep : null);
      if(R && inW!==R){ const gx=R.x, gy=R.y+R.h/2; if(Math.abs(pl.x-gx)>22 || pl.y<gy-4){ if(pl.y < gy+10 && Math.abs(pl.x-gx)>20){ wx=pl.x<gx?R.x-R.w/2-30:R.x+R.w/2+30; wy=gy+40; if(Math.abs(pl.x-wx)<20) {wx=gx; wy=gy+40;} } else { wx=gx; wy=gy+30; } } else { wx=gx; wy=R.y; } }
      if(T.y < F.gate.y && pl.y > F.gate.y+5){ if(Math.abs(pl.x-420)>25){ wx=420; wy=F.gate.y+40; } else { wx=420; wy=F.gate.y-40; } }
      if(inW && inW!==R){ const gx=inW.x, gy=inW.y+inW.h/2; if(Math.abs(pl.x-gx)>18 && pl.y<gy-20){ wx=gx; wy=gy-30; } else { wx=gx; wy=gy+60; } }
      { const RV=F.river, side=(y)=>y<RV.y0?-1:y>RV.y1?1:0, sp=side(pl.y), sw=side(wy); if(sw!==0 && sp!==sw){ const onBr=RV.bridges.some(([a,b])=>pl.x>a+10&&pl.x<b-10); if(!(onBr&&sp===0)){ const br=RV.bridges.map(([a,b])=>(a+b)/2).sort((a,b)=>(Math.abs(a-pl.x)+Math.abs(a-wx))-(Math.abs(b-pl.x)+Math.abs(b-wx)))[0]; if(Math.abs(pl.x-br)>12){ wx=br; wy= sp>0? RV.y1+34 : RV.y0-34; } else { wx=br; wy= sw<0? RV.y0-50 : RV.y1+50; } } else { wy = sw<0? RV.y0-50 : RV.y1+50; wx = pl.x; } } }
      // 벽 돌아가기: 목표로 가는 직선이 다른 울타리를 지나면 그 모서리로 돌아감
      { const encl=[...A.camps.map(c=>({x:c.x,y:c.y,w:c.w,h:c.h})), {x:F.keep.x,y:F.keep.y,w:F.keep.w,h:F.keep.h}];
        const hitSeg=(R,ax,ay,bx,by)=>{ const x0=R.x-R.w/2-26,x1=R.x+R.w/2+26,y0=R.y-R.h/2-26,y1=R.y+R.h/2+26; for(let i=0;i<=20;i++){const t=i/20,x=ax+(bx-ax)*t,y=ay+(by-ay)*t; if(x>x0&&x<x1&&y>y0&&y<y1) return true;} return false; };
        for(const E of encl){ if(B.insideWalls(pl) && Math.abs(B.insideWalls(pl).x-E.x)<1) continue; if(Math.abs(E.x-wx)<1&&Math.abs(E.y+E.h/2+30-wy)<45) continue; if(Math.abs(E.x-wx)<2&&Math.abs(E.y-wy)<2) continue;
          if(hitSeg(E,pl.x,pl.y,wx,wy)){ const cs=[[E.x-E.w/2-40,E.y-E.h/2-40],[E.x+E.w/2+40,E.y-E.h/2-40],[E.x-E.w/2-40,E.y+E.h/2+40],[E.x+E.w/2+40,E.y+E.h/2+40]].filter(([x,y])=>x>20&&x<F.W-20&&!hitSeg(E,pl.x,pl.y,x,y)); if(cs.length){ cs.sort((a,b)=>(Math.hypot(a[0]-pl.x,a[1]-pl.y)+Math.hypot(a[0]-wx,a[1]-wy))-(Math.hypot(b[0]-pl.x,b[1]-pl.y)+Math.hypot(b[0]-wx,b[1]-wy))); wx=cs[0][0]; wy=cs[0][1]; } break; } } }
      // 끼임 풀기
      window.__st=window.__st||{x:pl.x,y:pl.y,t:A.t,w:0}; const S=window.__st; if(A.t-S.t>2.5){ if(Math.hypot(pl.x-S.x,pl.y-S.y)<12 && !A.en.some(e=>Math.hypot(e.x-pl.x,e.y-pl.y)<120)) S.w=1.2; S.x=pl.x;S.y=pl.y;S.t=A.t; } if(S.w>0){ S.w-=1/30; wx=pl.x+Math.cos(A.t*0.7)*200; wy=pl.y+180; }
      let vx=(wx-pl.x), vy=(wy-pl.y); const dd=Math.hypot(vx,vy)||1; vx/=dd; vy/=dd; const fightR = A.ride?40:58;
      let near=0; for(const e of A.en){ const dx=pl.x-e.x,dy=pl.y-e.y,d=Math.hypot(dx,dy)||1; if(d<150) near++; if(d<fightR+e.r){ const w=(e.boss||e.elite)?2.5:1; vx+=dx/d*(fightR+e.r-d)/fightR*2.2*w; vy+=dy/d*(fightR+e.r-d)/fightR*2.2*w; } }
      for(const b of A.ebul){const dx=pl.x-b.x,dy=pl.y-b.y,d=Math.hypot(dx,dy)||1; if(d<60){vx+=dx/d/d*70;vy+=dy/d/d*70;}}
      // 싸울 거리 유지: 목표 근처 적이 있으면 너무 달리지 않음(걸어서)
      const ang=Math.atan2(vy,vx)+0.25, mv=Math.hypot(vx,vy)>0.15;
      K.arrowleft=mv&&Math.cos(ang)<-0.38; K.arrowright=mv&&Math.cos(ang)>0.38; K.arrowup=mv&&Math.sin(ang)<-0.38; K.arrowdown=mv&&Math.sin(ang)>0.38;
      if(A.horse && !A.ride && A.horse.st!=='down' && !inW && dd>420 && A.horse.st!=='come') B.horseBtn();
      if(A.ride && dd<120 && !R) B.horseBtn();
      if(A.mg>=100 && (near>=12 || (A.boss && Math.hypot(A.boss.x-pl.x,A.boss.y-pl.y)<120))) B.musouGo();
      B.update(1/30); }
    const A=B.A, T=B.fieldTarget(); return {st:A.state,t:Math.round(A.t),x:Math.round(A.p.x),y:Math.round(A.p.y),n:A.en.length,hp:Math.round(A.p.hp)+'/'+A.p.max,ride:A.ride?'R':'-',hh:A.horse?Math.round(A.horse.hp):0,lv:A.lvl,k:A.kills,cb:A.cbN,cbMax:A.cbMax,al:A.al.length,mg:Math.round(A.mg),cap:A.capN,home:Math.round(A.home.hp),vil:A.vil.st,tgt:T.n.slice(0,22),boss:A.boss?Math.round(A.boss.hp):null,sk:Object.entries(A.sk).map(([k,v])=>k+v+(A.evo[k]?'E':'')).join(','),tk:JSON.stringify(A.tk||{}),picks};},MODE);
  if(r.st==='snap'){ if(SHOTS){ await p.evaluate(()=>{const K=window.__BW.keys;for(const k in K)K[k]=false;}); if(r.nm!=='levelup') await p.waitForTimeout(60); await p.screenshot({path:OUT+TAG+'_s_'+r.nm+'.png'}); } continue; }
  if(r.gone||r.st!=='play'&&r.st!=='pick'){const x=await p.evaluate(()=>{const A=window.__BW.A;return A?JSON.stringify({t:A.t,tk:A.tk,lvl:A.lvl,k:A.kills,cap:A.capN,cbMax:A.cbMax,home:A.home.hp,vil:A.vil.st,sk:A.sk,evo:A.evo,boss:A.boss&&Math.round(A.boss.hp)}):''});stats.push('END '+JSON.stringify(r)+' '+x); break;}
  if(chunk%3===0) stats.push(JSON.stringify({...r,picks:undefined}));
  if(SHOTS&&si<shotAt.length&&r.t>=shotAt[si]){await p.evaluate(()=>{const K=window.__BW.keys;for(const k in K)K[k]=false;}); await p.waitForTimeout(120); await p.screenshot({path:OUT+TAG+'_t'+shotAt[si]+'.png'}); si++;}
}
await p.evaluate(()=>{const K=window.__BW.keys;for(const k in K)K[k]=false;});
await p.waitForTimeout(2200); if(SHOTS) await p.screenshot({path:OUT+TAG+'_end.png'});
const sv=await p.evaluate(()=>JSON.stringify(window.__BW.muSV()));
console.log(stats.join('\n')); console.log('SV',sv); console.log('ERR',[...new Set(errs)]);
await b.close();})();
