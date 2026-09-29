/* Local ONNX inference worker. No photograph leaves this origin. */
importScripts('vendor/onnx/ort.wasm.min.js');
ort.env.wasm.numThreads = 1;
ort.env.wasm.proxy = false;
ort.env.wasm.wasmPaths = new URL('vendor/onnx/', self.location.href).href;
let session;
self.onmessage = async ({data}) => {
  let input, outputs;
  try {
    session ??= ort.InferenceSession.create(
      new URL('assets/packages/image_background_remover/assets/model.onnx', self.location.href).href,
      {executionProviders:['wasm'], graphOptimizationLevel:'all'}
    ).catch(error => { session = null; throw error; });
    const model = await session;
    input = new ort.Tensor('float32', data.tensor, [1,3,320,320]);
    outputs = await model.run({[model.inputNames[0]]:input});
    const result = outputs[model.outputNames[0]];
    const mask = new Float32Array(result.data.slice(0,320*320));
    self.postMessage({mask},[mask.buffer]);
  } catch (error) {
    self.postMessage({error:String(error.message || error)});
  } finally {
    input?.dispose();
    if(outputs) for(const tensor of Object.values(outputs)) tensor.dispose();
  }
};
