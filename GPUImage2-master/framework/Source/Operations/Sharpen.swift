public class Sharpen: BasicOperation {
    public var sharpness:Float = 0.0 { didSet { uniformSettings["sharpness"] = sharpness } }
    public var overriddenTexelSize:Size?
    
    public init() {
        super.init(vertexShader:SharpenVertexShader, fragmentShader:SharpenFragmentShader, numberOfInputs:1)
        
        ({sharpness = 0.0})()
    }
    
    override func configureFramebufferSpecificUniforms(inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)
        let texelSize = overriddenTexelSize ?? inputFramebuffer.texelSizeForRotation(outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
    }
}