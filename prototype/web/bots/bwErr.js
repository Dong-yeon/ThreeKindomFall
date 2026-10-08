const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await (await b.newContext({viewport:{width:360,height:780}})).newPage();const errs=[];p.on('pageerror',e=>errs.push('PE '+e.message+' | '+(e.stack||'').split('\n').slice(0,3).join(' ')));
await p.goto(require('url').pathToFileURL(require('path').resolve(__dirname,'../dist/index.html')).href);await p.waitForTimeout(1500); console.log(errs.join('\n')); await b.close();})();
