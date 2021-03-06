// Erwin Mazariegos
// Altconf 2018: AR+SceneKit Tips & Tricks

import Foundation
import SceneKit
import SpriteKit

extension Demos {

	public struct Measurement {

		public enum DemoMode {
			case one, random, many
		}

		public static func runwithView(_ sceneView: ARView, mode: DemoMode) {
			LogFunc()

			let radius: CGFloat = 0.05

			// common start point for all rulers in this demo
			let start = SCNNode(geometry: SCNSphere(radius: radius))
			start.geometry?.materials = [SCNMaterial.black]
			start.position = SCNVector3(x: 0, y: 0, z: -1)
			sceneView.scene?.rootNode.addChildNode(start)

			func addRulerTo(_ endPoint: SCNVector3) {

				let end = SCNNode(geometry: SCNSphere(radius: radius))
				end.geometry?.materials = [SCNMaterial.white]
				end.position = endPoint
				sceneView.scene?.rootNode.addChildNode(end)

				let ruler = Ruler(startPosition: start.position, material: SCNMaterial.blue, radius: radius / 2)
				sceneView.scene?.rootNode.addChildNode(ruler)
				ruler.measureTo(end.position)

				let pane = PictureNode(at: start.position)
				sceneView.scene?.rootNode.addChildNode(pane)
				pane.followRuler(ruler)
				pane.showPivot()
				pane.showAxes()

				let measurment = "\(ruler.lengthInUnit(.feet))"
				let lengthText = SCNText(string: measurment, extrusionDepth: 0.2)
				lengthText.font = NSFont(name: "Helvetica", size: 1)
				lengthText.materials = [SCNMaterial.black]

				let lengthTextNode = SCNNode(geometry: lengthText)
				lengthTextNode.position = endPoint
				lengthTextNode.rotation = pane.rotation
				lengthTextNode.scale = SCNVector3(0.5, 0.5, 0.5)
				sceneView.scene?.rootNode.addChildNode(lengthTextNode)

				let pointText = SCNText(string: "{\(endPoint.x), \(endPoint.y), \(endPoint.z)}", extrusionDepth: 0.1)
				pointText.font = NSFont(name: "Helvetica", size: 0.75)
				pointText.materials = [SCNMaterial.black]

				let pointTextNode = SCNNode(geometry: pointText)
				pointTextNode.position = endPoint
				pointTextNode.position.y -= 0.5
				pointTextNode.rotation = pane.rotation
				pointTextNode.scale = SCNVector3(0.5, 0.5, 0.5)
				sceneView.scene?.rootNode.addChildNode(pointTextNode)
			}

			let points = [
				SCNVector3(4, 0, 0),
				SCNVector3(-2, 2, -3),
				SCNVector3(6, 2, -3),
				SCNVector3(-2, 3, 3),
				SCNVector3(-2, -2.2, 1)
			]

			switch mode {
			case .one:
				addRulerTo(points[0])
			case .random:
				let point = points[Int(arc4random_uniform(UInt32(points.count - 1)))]
				addRulerTo(point)
			case .many:
				points.forEach({ addRulerTo($0) })
			}
		}

	}

}
