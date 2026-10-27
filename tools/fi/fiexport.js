const puppeteer = require('puppeteer-core');
const fs = require('fs');
(async()=>{
  const b=await puppeteer.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:'new',args:['--no-sandbox']});
  const p=await b.newPage();
  p.on('pageerror',e=>console.log('PAGEERR:',e.message.slice(0,160)));
  const js=fs.readFileSync('stickers/stickers.js','utf8');
  await p.setContent(`<body><script type="module">${js}
    window.F={loupe,sprout,medal,tile,paint,draw,PALETTES,scene:undefined};
    window.renderSheet=(icon,cell,every,still)=>{
      const frames=[];
      const n=icon.frames;const pal=PALETTES.matcha;
      for(let f=0;f<n;f+=every)frames.push(f);
      if(!frames.includes(still??-1)){}
      const W=frames.length*cell;
      const sheet=document.createElement('canvas');sheet.width=W;sheet.height=cell;
      const sc=sheet.getContext('2d');
      const tmp=document.createElement('canvas');tmp.width=tmp.height=cell;
      frames.forEach((f,i)=>{
        const tc=tmp.getContext('2d');tc.setTransform(1,0,0,1,0,0);tc.clearRect(0,0,cell,cell);
        paint(tmp,icon,f,1,pal);
        sc.drawImage(tmp,i*cell,0);
      });
      return{data:sheet.toDataURL('image/png'),frames:frames.length};
    };</script></body>`);
  await new Promise(r=>setTimeout(r,700));
  fs.mkdirSync('mobile/assets/stickers',{recursive:true});
  const spec={
    loupe:{every:4,still:40},
    sprout:{every:4,still:92},
    tile:{every:4,still:84},
    medal:{every:4,still:94,until:97},
  };
  for(const[name,s]of Object.entries(spec)){
    const r=await p.evaluate((nm,ev,st,until)=>{
      const icon=window.F[nm];
      const src=until?{...icon,frames:until}:icon;
      const cell=160;
      const out=window.renderSheet(src,cell,ev,st);
      return out;
    },name,s.every,s.still,s.until||0);
    const buf=Buffer.from(r.data.split(',')[1],'base64');
    fs.writeFileSync(`mobile/assets/stickers/${name}.png`,buf);
    console.log(name,'frames:',r.frames,'bytes:',buf.length);
  }
  // also write still-only 1-frame poster for reduced-motion fallback? widget can reuse sheet's still frame — no extra file needed.
  await b.close();
})().catch(e=>console.log('FATAL',e.message));
