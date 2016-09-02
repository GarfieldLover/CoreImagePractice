// MARK: -
// MARK: Basic types

public protocol ImageSource {
    var targets:TargetContainer { get }
    func transmitPreviousImageToTarget(target:ImageConsumer, atIndex:UInt)
}

public protocol ImageConsumer:AnyObject {
    var maximumInputs:UInt { get }
    var sources:SourceContainer { get }
    
    func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt)
}

public protocol ImageProcessingOperation: ImageConsumer, ImageSource {
}

infix operator --> { associativity left precedence 140 }

public func --><T:ImageConsumer>(source:ImageSource, destination:T) -> T {
    source.addTarget(destination)
    return destination
}

// MARK: -
// MARK: Extensions and supporting types

public extension ImageSource {
    public func addTarget(target:ImageConsumer, atTargetIndex:UInt? = nil) {
        if let targetIndex = atTargetIndex {
            target.setSource(self, atIndex:targetIndex)
            targets.append(target, indexAtTarget:targetIndex)
            transmitPreviousImageToTarget(target, atIndex:targetIndex)
        } else if let indexAtTarget = target.addSource(self) {
            targets.append(target, indexAtTarget:indexAtTarget)
            transmitPreviousImageToTarget(target, atIndex:indexAtTarget)
        } else {
            debugPrint("Warning: tried to add target beyond target's input capacity")
        }
    }

    public func removeAllTargets() {
        for (target, index) in targets {
            target.removeSourceAtIndex(index)
        }
        targets.removeAll()
    }
    
    public func updateTargetsWithFramebuffer(framebuffer:Framebuffer) {
        if targets.count == 0 { // Deal with the case where no targets are attached by immediately returning framebuffer to cache
            framebuffer.lock()
            framebuffer.unlock()
        } else {
            // Lock first for each output, to guarantee proper ordering on multi-output operations
            for _ in targets {
                framebuffer.lock()
            }
        }
        for (target, index) in targets {
            target.newFramebufferAvailable(framebuffer, fromSourceIndex:index)
        }
    }
}

public extension ImageConsumer {
    public func addSource(source:ImageSource) -> UInt? {
        return sources.append(source, maximumInputs:maximumInputs)
    }
    
    public func setSource(source:ImageSource, atIndex:UInt) {
        sources.insert(source, atIndex:atIndex, maximumInputs:maximumInputs)
    }

    public func removeSourceAtIndex(index:UInt) {
        sources.removeAtIndex(index)
    }
}

class WeakImageConsumer {
    weak var value:ImageConsumer?
    let indexAtTarget:UInt
    init (value:ImageConsumer, indexAtTarget:UInt) {
        self.indexAtTarget = indexAtTarget
        self.value = value
    }
}

public class TargetContainer:SequenceType {
    var targets = [WeakImageConsumer]()
    var count:Int { get {return targets.count}}

    public init() {
    }
    
    public func append(target:ImageConsumer, indexAtTarget:UInt) {
        // TODO: Don't allow the addition of a target more than once
        targets.append(WeakImageConsumer(value:target, indexAtTarget:indexAtTarget))
    }
    
    public func generate() -> AnyGenerator<(ImageConsumer, UInt)> {
        var index = 0
        
        return AnyGenerator { () -> (ImageConsumer, UInt)? in
            if (index >= self.targets.count) {
                return nil
            }
            
            while (self.targets[index].value == nil) {
                self.targets.removeAtIndex(index)
                if (index >= self.targets.count) {
                    return nil
                }
            }
            
            index += 1
            return (self.targets[index - 1].value!, self.targets[index - 1].indexAtTarget)
        }
    }
    
    public func removeAll() {
        targets.removeAll()
    }
}

public class SourceContainer {
    var sources:[UInt:ImageSource] = [:]
    
    public init() {
    }
    
    public func append(source:ImageSource, maximumInputs:UInt) -> UInt? {
        var currentIndex:UInt = 0
        while currentIndex < maximumInputs {
            if (sources[currentIndex] == nil) {
                sources[currentIndex] = source
                return currentIndex
            }
            currentIndex += 1
        }
        
        return nil
    }
    
    public func insert(source:ImageSource, atIndex:UInt, maximumInputs:UInt) -> UInt {
        guard (atIndex < maximumInputs) else { fatalError("ERROR: Attempted to set a source beyond the maximum number of inputs on this operation") }
        sources[atIndex] = source
        return atIndex
    }
    
    public func removeAtIndex(index:UInt) {
        sources[index] = nil
    }
}

public class ImageRelay: ImageProcessingOperation {
    public var newImageCallback:((Framebuffer) -> ())?
    
    public let sources = SourceContainer()
    public let targets = TargetContainer()
    public let maximumInputs:UInt = 1
    public var preventRelay:Bool = false
    
    init() {
    }
    
    public func transmitPreviousImageToTarget(target:ImageConsumer, atIndex:UInt) {
        sources.sources[0]?.transmitPreviousImageToTarget(self, atIndex:0)
    }

    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        if let newImageCallback = newImageCallback {
            newImageCallback(framebuffer)
        }
        if (!preventRelay) {
            relayFramebufferOnward(framebuffer)
        }
    }
    
    public func relayFramebufferOnward(framebuffer:Framebuffer) {
        // Need to override to guarantee a removal of the previously applied lock
        for _ in targets {
            framebuffer.lock()
        }
        framebuffer.unlock()
        for (target, index) in targets {
            target.newFramebufferAvailable(framebuffer, fromSourceIndex:index)
        }
    }
}
