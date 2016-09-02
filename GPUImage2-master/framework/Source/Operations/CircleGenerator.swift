#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL
#endif
#endif

public class CircleGenerator: ImageGenerator {
    let circleShader:ShaderProgram
    
    public override init(size:Size) {
        circleShader = crashOnShaderCompileFailure("CircleGenerator"){try sharedImageProcessingContext.programForVertexShader(CircleVertexShader, fragmentShader:CircleFragmentShader)}
        circleShader.colorUniformsUseFourComponents = true
        super.init(size:size)
    }

    public func renderCircleOfRadius(radius:Float, center:Position, circleColor:Color = Color.White, backgroundColor:Color = Color.Black) {
        let scaledRadius = radius * 2.0
        imageFramebuffer.activateFramebufferForRendering()
        var uniformSettings = ShaderUniformSettings()
        uniformSettings["circleColor"] = circleColor
        uniformSettings["backgroundColor"] = backgroundColor
        uniformSettings["radius"] = scaledRadius
        uniformSettings["aspectRatio"] = imageFramebuffer.aspectRatioForRotation(.NoRotation)
        
        let convertedCenterX = (Float(center.x) * 2.0) - 1.0
        let convertedCenterY = (Float(center.y) * 2.0) - 1.0
        let scaledYRadius = scaledRadius / imageFramebuffer.aspectRatioForRotation(.NoRotation)

        uniformSettings["center"] = Position(convertedCenterX, convertedCenterY)
        let circleVertices:[GLfloat] = [GLfloat(convertedCenterX - scaledRadius), GLfloat(convertedCenterY - scaledYRadius), GLfloat(convertedCenterX + scaledRadius), GLfloat(convertedCenterY - scaledYRadius), GLfloat(convertedCenterX - scaledRadius), GLfloat(convertedCenterY + scaledYRadius), GLfloat(convertedCenterX + scaledRadius), GLfloat(convertedCenterY + scaledYRadius)]
        
        clearFramebufferWithColor(backgroundColor)
        circleShader.use()
        uniformSettings.restoreShaderSettings(circleShader)
        
        guard let positionAttribute = circleShader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
        glVertexAttribPointer(positionAttribute, 2, GLenum(GL_FLOAT), 0, 0, circleVertices)
        
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        
        notifyTargets()
    }
}