const {chromium}=require('playwright');
require('fs').mkdirSync(require('path').resolve(__dirname,'../out'),{recursive:true});
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({viewport:{width:360,height:780},deviceScaleFactor:2,hasTouch:true});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push('PE '+e.message+' '+(e.stack||'').split('\n')[1]));
await p.goto(require('url').pathToFileURL(require('path').resolve(__dirname,'../dist/index.html')).href);await p.waitForTimeout(1000);
await p.click('[data-ch="f1"]'); await p.waitForTimeout(400);
const r=await p.evaluate(()=>{const B=window.__BW, A=B.A; A.ride=false; if(A.horse) A.horse.st='idle'; A.en.length=0; A.vil.at=9999; A.partyT=9999; A.reinT=9999; A.p.x=190; A.p.y=1880; A.p.inv=999; A.p.hp=99999; A.p.max=99999; A.cb.t=999;
  const c=A.camps[0]; for(let i=0;i<12;i++){ window.__BW.update; } 
  const before=A.en.length; return {before, camp:[c.x,c.y,c.w,c.h]};});
// spawn chasers inside camp A
await p.evaluate(()=>{const A=window.__BW.A; for(let i=0;i<12;i++){ const e={side:'en',k:'ytb',x:120+i*12,y:2040+(i%3)*20,r:10,hp:999,max:999,spd:74,touch:0,ai:'chase',t:0,st:0,vx:0,vy:0,flash:0,phase:0}; A.en.push(e);} A.camps.forEach(c=>c.spawnT=9999);});
const log=[];
for(let s=0;s<12;s++){ const q=await p.evaluate(()=>{const B=window.__BW,A=B.A; for(let i=0;i<30;i++){ A.cb.t=999; B.update(1/30);} const d=A.en.map(e=>Math.round(Math.hypot(e.x-A.p.x,e.y-A.p.y))); return {t:Math.round(A.t),near:d.filter(x=>x<70).length,ys:A.en.map(e=>Math.round(e.y)).slice(0,6).join(','),xs:A.en.map(e=>Math.round(e.x)).slice(0,6).join(',')};}); log.push(JSON.stringify(q)); }
await p.screenshot({path:require('path').resolve(__dirname,'../out/v15_path.png')});
// full map
await p.evaluate(()=>{const A=window.__BW.A; A.p.inv=0; A.cb.t=0.2;}); await p.evaluate(()=>window.__BW.fieldMapOpen()); await p.waitForTimeout(300); await p.screenshot({path:require('path').resolve(__dirname,'../out/v15_map.png')});
console.log(log.join('\n')); console.log('ERR',errs); await b.close();})();
