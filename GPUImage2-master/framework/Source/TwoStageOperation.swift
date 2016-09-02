public class TwoStageOperation: BasicOperation {
    public var overrideDownsamplingOptimization:Bool = false

//    override var outputFramebuffer:Framebuffer { get { return Framebuffer } }

    var downsamplingFactor:Float?

    override func internalRenderFunction(inputFramebuffer:Framebuffer, textureProperties:[InputTextureProperties]) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)

        // Downsample
        let internalStageSize:GLSize
        let firstStageTextureProperties:[InputTextureProperties]
        let downsamplingFramebuffer:Framebuffer?
        if let downsamplingFactor = downsamplingFactor {
            internalStageSize = GLSize(Size(width:max(5.0, Float(renderFramebuffer.size.width) / downsamplingFactor), height:max(5.0, Float(renderFramebuffer.size.height) / downsamplingFactor)))
            downsamplingFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:internalStageSize, stencil:false)
            downsamplingFramebuffer!.lock()
            downsamplingFramebuffer!.activateFramebufferForRendering()
            clearFramebufferWithColor(backgroundColor)
            renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:nil, vertices:standardImageVertices, inputTextures:textureProperties)
            releaseIncomingFramebuffers()

            firstStageTextureProperties = [downsamplingFramebuffer!.texturePropertiesForOutputRotation(.NoRotation)]
        } else {
            firstStageTextureProperties = textureProperties
            internalStageSize = renderFramebuffer.size
            downsamplingFramebuffer = nil
        }

        // Render first stage
        let firstStageFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:internalStageSize, stencil:false)
        firstStageFramebuffer.lock()

        firstStageFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        
        let texelSize = inputFramebuffer.initialStageTexelSizeForRotation(outputRotation)
        uniformSettings["texelWidth"] = texelSize.width * (downsamplingFactor ?? 1.0)
        uniformSettings["texelHeight"] = texelSize.height * (downsamplingFactor ?? 1.0)
        
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:firstStageTextureProperties)
        if let downsamplingFramebuffer = downsamplingFramebuffer {
            downsamplingFramebuffer.unlock()
        } else {
            releaseIncomingFramebuffers()
        }
        
        let secondStageTexelSize = renderFramebuffer.texelSizeForRotation(.NoRotation)
        uniformSettings["texelWidth"] = secondStageTexelSize.width * (downsamplingFactor ?? 1.0)
        uniformSettings["texelHeight"] = 0.0
        
        // Render second stage and upsample
        if (downsamplingFactor != nil) {
            let beforeUpsamplingFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:internalStageSize, stencil:false)
            beforeUpsamplingFramebuffer.activateFramebufferForRendering()
            beforeUpsamplingFramebuffer.lock()
            clearFramebufferWithColor(backgroundColor)
            renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.NoRotation)])
            firstStageFramebuffer.unlock()
            
            renderFramebuffer.activateFramebufferForRendering()
            renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:nil, vertices:standardImageVertices, inputTextures:[beforeUpsamplingFramebuffer.texturePropertiesForOutputRotation(.NoRotation)])
            beforeUpsamplingFramebuffer.unlock()
        } else {
            renderFramebuffer.activateFramebufferForRendering()
            renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.NoRotation)])
            firstStageFramebuffer.unlock()
        }
    }
}