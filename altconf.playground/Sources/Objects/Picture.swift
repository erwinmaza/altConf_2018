import Foundation
import SceneKit


public class PictureNode: SCNNode {

	private let pane = SCNPlane()

	public init(at placement: SCNVector3) {
		super.init()

		let photo = #imageLiteral(resourceName: "landscape1.jpg")
		let material = SCNMaterial()
		material.diffuse.contents = photo
		material.isDoubleSided = true
		pane.materials = [material]

		pane.height = 8 * 0.3048
		pane.width = 0

		geometry = pane
		position = placement
	}

	public override init() {
		super.init()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public func followRuler(_ ruler: Ruler) {
		pane.width = ruler.measurement
		pivot = SCNMatrix4Translate(SCNMatrix4Identity, CGFloat(-pane.width / 2), CGFloat(-pane.height / 2), 0)

		let xDegrees = ruler.rotation.x < 0 ? .pi / 2 : -CGFloat.pi / 2

		var newTransform = ruler.transform
		newTransform = SCNMatrix4Rotate(newTransform, .pi / 2, 0, 0, 1)
		newTransform = SCNMatrix4Rotate(newTransform, xDegrees, 1, 0, 0)
		transform = newTransform
	}
}
