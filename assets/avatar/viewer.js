/* Local-only viewer. Mesh/texture assets: MakeHuman CC0; renderer: Three.js MIT. */
(() => {
  const report = (type, detail = '') => window.StyloBridge?.postMessage(JSON.stringify({type, detail}));
  try {
    const renderer = new THREE.WebGLRenderer({antialias:true, alpha:true});
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.25;
    document.body.appendChild(renderer.domElement);
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(32, 1, .01, 30);
    const avatar = new THREE.Group(); scene.add(avatar);
    scene.add(new THREE.HemisphereLight(0xeaf1ff, 0x303040, 2.1));
    const key = new THREE.DirectionalLight(0xffeee3, 3.2);key.position.set(-2,3,4);scene.add(key);
    const rim = new THREE.DirectionalLight(0xff927d, 2.0);rim.position.set(2,2,-2);scene.add(rim);
    const fill = new THREE.DirectionalLight(0xbbd9ff, 1.2);fill.position.set(2,1,3);scene.add(fill);
    const floor = new THREE.Mesh(new THREE.CylinderGeometry(.48,.5,.025,64),new THREE.MeshStandardMaterial({color:0x202635,roughness:.65,metalness:.2}));scene.add(floor);
    let currentSex = '', radius = 3.8, yaw = 0, pitch = 0, targetY = .9;
    let disposed = false, frame = 0, generation = 0;
    function draw(){frame=0;if(disposed)return;camera.position.set(Math.sin(yaw)*radius, targetY+pitch,Math.cos(yaw)*radius);camera.lookAt(0,targetY,0);renderer.render(scene,camera);}
    function requestDraw(){if(!frame)frame=requestAnimationFrame(draw);}
    function clear(){for(const mesh of [...avatar.children]){mesh.geometry.dispose();mesh.material.map?.dispose();mesh.material.dispose();avatar.remove(mesh);}}
    function load(sex){
      if(currentSex===sex)return; currentSex=sex;clear();const version=++generation;
      const tasks=[];
      for(const part of STYLO_MODELS[sex]){
        const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(part.positions,3));geometry.setAttribute('uv',new THREE.Float32BufferAttribute(part.uv,2));geometry.setIndex(part.indices);geometry.computeVertexNormals();
        const material=new THREE.MeshStandardMaterial({color:0xffffff,roughness:part.name==='eyes'?.35:.86,side:THREE.DoubleSide,alphaTest:part.name==='hair'?.35:0});
        const mesh=new THREE.Mesh(geometry,material);avatar.add(mesh);
        const file=part.name==='body'?`${sex}-skin.png`:part.name==='hair'?`${sex}-hair.png`:'eyes.png';
        tasks.push(new Promise((resolve,reject)=>new THREE.TextureLoader().load(file, texture=>{if(version!==generation){texture.dispose();resolve();return;}texture.colorSpace=THREE.SRGBColorSpace;material.map=texture;material.needsUpdate=true;requestDraw();resolve();},undefined,reject)));
      }
      avatar.position.set(0,0,0);const box=new THREE.Box3().setFromObject(avatar);avatar.position.y=-box.min.y+.03;targetY=(box.max.y-box.min.y)/2;radius=3.8;requestDraw();
      Promise.all(tasks).then(()=>{if(version===generation)report('ready');}).catch(()=>report('error','Texturile avatarului nu au putut fi încărcate.'));
    }
    window.styloUpdate = state => {
      load(state.profile==='Feminin'?'female':'male');
      scene.background=new THREE.Color(state.background||'#151923');floor.material.color.set(state.floor||'#202635');rim.color.set(state.accent||'#ff927d');requestDraw();
    };
    window.styloReset=()=>{yaw=0;pitch=0;radius=3.8;requestDraw();};
    const pointers=new Map();let previousDistance=0;
    const canvas=renderer.domElement;
    canvas.addEventListener('pointerdown',e=>{canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,[e.clientX,e.clientY]);});
    canvas.addEventListener('pointermove',e=>{if(!pointers.has(e.pointerId))return;const previous=pointers.get(e.pointerId);pointers.set(e.pointerId,[e.clientX,e.clientY]);if(pointers.size===1){yaw-=(e.clientX-previous[0])*.012;pitch=Math.max(-.65,Math.min(.65,pitch+(e.clientY-previous[1])*.006));}else{const p=[...pointers.values()];const distance=Math.hypot(p[0][0]-p[1][0],p[0][1]-p[1][1]);if(previousDistance)radius=Math.max(2.3,Math.min(5.5,radius*previousDistance/distance));previousDistance=distance;}requestDraw();});
    for(const event of ['pointerup','pointercancel'])canvas.addEventListener(event,e=>{pointers.delete(e.pointerId);previousDistance=0;});
    canvas.addEventListener('wheel',e=>{e.preventDefault();radius=Math.max(2.3,Math.min(5.5,radius+e.deltaY*.003));requestDraw();},{passive:false});
    function resize(){const w=innerWidth,h=innerHeight;renderer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();requestDraw();}addEventListener('resize',resize);
    canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();report('error','Randarea 3D a fost întreruptă. Reîncarcă avatarul.');});
    addEventListener('pagehide',()=>{disposed=true;cancelAnimationFrame(frame);clear();renderer.dispose();});
    resize();window.styloUpdate({profile:'Masculin'});
  } catch(error){document.getElementById('error').hidden=false;document.getElementById('error').textContent='Avatarul 3D nu poate fi afișat pe acest dispozitiv.';report('error',String(error));}
})();
