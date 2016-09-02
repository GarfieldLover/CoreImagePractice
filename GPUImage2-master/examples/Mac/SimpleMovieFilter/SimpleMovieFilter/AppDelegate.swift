import Cocoa
import GPUImage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var renderView: RenderView!
    
    var movie:MovieInput!
    var filter:Pixellate!
    
    dynamic var filterValue = 0.05 {
        didSet {
            filter.fractionalWidthOfAPixel = GLfloat(filterValue)
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let bundleURL = NSBundle.mainBundle().resourceURL!
        let movieURL = NSURL(string:"sample_iPod.m4v", relativeToURL:bundleURL)!

        do {
            movie = try MovieInput(url:movieURL, playAtActualSpeed:true)
            filter = Pixellate()
            movie --> filter --> renderView
            movie.runBenchmark = true
            movie.start()
        } catch {
            print("Couldn't process movie with error: \(error)")
        }
    }
}

