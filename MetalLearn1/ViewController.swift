//
//  ViewController.swift
//  MetalLearn1
//
//  Created by Utkarsh Gupta on 08/04/22.
//

import Metal
import UIKit
import QuartzCore

class ViewController: UIViewController {
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var vertexBuffer: MTLBuffer! = nil
    let vertexData: [Float] = [
         0.0,  0.5, 0.0,
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0
    ]
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create GPU
        device = MTLCreateSystemDefaultDevice()
        
        // Create Core Animation Layer & attach to GPU (To enable screen to talk to user)
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        // Determine size of vertexArray and create a vertexBuffer for Vertex Shader
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: dataSize,
                                         options: [.storageModeShared])
        
        // Create a library to hold the compiled shader functions & add it to pipeline
        let defaultLibrary = device.makeDefaultLibrary()
        let fragmentProgram = defaultLibrary!.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
        
        // set up render pipeline
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // command queue setup (to submit all the work to GPU)
        commandQueue = device.makeCommandQueue()
        
        // every time screen refreshes, run the selected function
        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    /// Runs everytime a new frame needs to be rendered
    func render() {
        // setup render pass
        let renderPassDescriptor = MTLRenderPassDescriptor()
        guard let drawable = metalLayer.nextDrawable() else {return}
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor =
        MTLClearColor(red: 221.0/255.0, green: 160.0/255.0, blue: 221.0/255.0, alpha: 1.0)
        
        // command buffer to encode the pipeline & vertex data
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
    }
    
    // like the "update" method of unity
    @objc func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
}

