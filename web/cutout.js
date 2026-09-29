/* Browser photo pipeline, bounded to 1280px with off-main-thread inference. */
(() => {
  let worker = null, busy = false;
  const canvas = (w,h) => Object.assign(document.createElement('canvas'),{width:w,height:h});
  function infer(tensor) {
    return new Promise((resolve,reject) => {
      worker ??= new Worker(new URL('cutout-worker.js', document.baseURI));
      const active = worker;
      const finish = (error,mask) => {
        clearTimeout(timer); active.onmessage=null; active.onerror=null;
        if(error) { active.terminate(); if(worker===active) worker=null; reject(error); }
        else resolve(mask);
      };
      const timer=setTimeout(()=>finish(new Error('Procesarea a durat prea mult. Încearcă o fotografie mai mică.')),180000);
      active.onmessage=({data})=>finish(data.error?new Error(data.error):null,data.mask);
      active.onerror=event=>finish(new Error(event.message || 'Motorul de decupare nu a putut fi încărcat.'));
      active.postMessage({tensor},[tensor.buffer]);
    });
  }
  async function decode(bytes) {
    const url=URL.createObjectURL(new Blob([bytes]));
    try {
      const image=new Image();
      await new Promise((resolve,reject)=>{ image.onload=resolve; image.onerror=()=>reject(new Error('Format foto necunoscut. Folosește JPG, PNG sau WebP.')); image.src=url; });
      return image;
    } finally { URL.revokeObjectURL(url); }
  }
  window.styloRemoveBackground = async (bytes,threshold) => {
    if(busy) throw new Error('O fotografie este deja procesată.');
    busy=true;
    const resources=[];
    try {
      const image=await decode(bytes);
      const scale=Math.min(1,1280/Math.max(image.naturalWidth,image.naturalHeight));
      const w=Math.max(1,Math.round(image.naturalWidth*scale)),h=Math.max(1,Math.round(image.naturalHeight*scale));
      const original=canvas(w,h), small=canvas(320,320);
      resources.push(original,small);
      const ctx=original.getContext('2d',{willReadFrequently:true});
      ctx.drawImage(image,0,0,w,h);
      const mini=small.getContext('2d',{willReadFrequently:true});
      mini.drawImage(original,0,0,320,320);
      const rgb=mini.getImageData(0,0,320,320).data;
      const tensor=new Float32Array(3*320*320), pixels=320*320;
      const mean=[.485,.456,.406],std=[.229,.224,.225];
      for(let i=0;i<pixels;i++) for(let c=0;c<3;c++) tensor[c*pixels+i]=(rgb[i*4+c]/255-mean[c])/std[c];
      const mask=await infer(tensor);
      const rgba=ctx.getImageData(0,0,w,h);
      let left=w,top=h,right=-1,bottom=-1,visible=0;
      for(let y=0;y<h;y++) {
        const fy=y*319/Math.max(1,h-1),y0=Math.floor(fy),y1=Math.min(319,y0+1),wy=fy-y0;
        for(let x=0;x<w;x++) {
          const fx=x*319/Math.max(1,w-1),x0=Math.floor(fx),x1=Math.min(319,x0+1),wx=fx-x0;
          const m=mask[y0*320+x0]*(1-wx)*(1-wy)+mask[y0*320+x1]*wx*(1-wy)+mask[y1*320+x0]*(1-wx)*wy+mask[y1*320+x1]*wx*wy;
          const i=(y*w+x)*4+3;
          rgba.data[i]=Math.round(rgba.data[i]*Math.max(0,Math.min(1,(m-threshold+.05)/.1)));
          if(rgba.data[i]>24) {visible++;left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);}
        }
        // Yield for scrolling/painting while applying a large mask.
        if(y%80===0) await new Promise(resolve=>setTimeout(resolve,0));
      }
      if(visible<w*h*.003 || right<left) throw new Error('Haina nu a fost detectată. Păstrează originalul sau încearcă altă fotografie.');
      ctx.putImageData(rgba,0,0);
      left=Math.max(0,left-4);top=Math.max(0,top-4);right=Math.min(w-1,right+4);bottom=Math.min(h-1,bottom+4);
      const trimmed=canvas(right-left+1,bottom-top+1);resources.push(trimmed);
      trimmed.getContext('2d').drawImage(original,left,top,trimmed.width,trimmed.height,0,0,trimmed.width,trimmed.height);
      const blob=await new Promise(resolve=>trimmed.toBlob(resolve,'image/png'));
      if(!blob) throw new Error('Imaginea decupată nu a putut fi creată.');
      return new Uint8Array(await blob.arrayBuffer());
    } finally {
      for(const c of resources) {c.width=1;c.height=1;}
      busy=false;
    }
  };
})();
