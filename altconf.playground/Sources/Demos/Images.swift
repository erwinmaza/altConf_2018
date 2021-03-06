// Erwin Mazariegos
// Altconf 2018: AR+SceneKit Tips & Tricks

import Foundation
import SceneKit
import SpriteKit

public extension Demos {

	public class Images {

		public enum DemoMode {
			case one, many, addMob
		}

		public var hitTestNaive = true

		
		let panelAnimationDuration = 1.0
		let baseNodeScale: CGFloat = 0.02

		var currentPanel: ImagePanel?
		var panelBaseRadius: CGFloat = 1.0
		var panelMidPoint: CGFloat = 0
		var panelSpacingDegrees: CGFloat = 0
		var clickGesture: NSClickGestureRecognizer?
		var demoSceneView: ARView?

		public init() {
			LogFunc()
		}

		public func runwithView(_ sceneView: ARView, mode: DemoMode) {
			LogFunc()

			let imageMap = [
				("Fire Hill", "landscape1.jpg"),
				("Gate Up", "landscape2.jpg"),
				("San Jose", "landscape3.jpg"),
				("Golden Span", "landscape2.jpg"),
				("Gray Drama", "landscape3.jpg")
			]

			let minimumPanelRadius: CGFloat = 1.0

			panelSpacingDegrees = 180.0 / CGFloat(imageMap.count)
			panelMidPoint = 0.5 * CGFloat(imageMap.count - 1)
			panelBaseRadius = max(minimumPanelRadius, CGFloat(imageMap.count) * 1.4)

			demoSceneView = sceneView

			switch mode {
			case .one:

				let image = Image.withName(imageMap[0].1)
				let imagePanel = ImagePanel(title: imageMap[0].0, image: image, index: 0)
				sceneView.scene?.rootNode.addChildNode(imagePanel)

			case .many:
				addAllImagesInMap(imageMap)
				addTextNodes()
				addClickRecognizer()
			case .addMob:
				addAllImagesInMap(imageMap)
				addTextNodes()
				addMob()
			}
		}

		func addAllImagesInMap(_ imageMap: [(String, String)]) {
			LogFunc()
			for (index, map) in imageMap.enumerated() {
				let image = Image.withName(map.1)
				let imagePanel = ImagePanel(title: map.0, image: image, index: index)

				let degreesFromCenter = degreesFromCenterForPanelIndex(index)
				imagePanel.position = positionForDegreesFromCenter(degreesFromCenter, atRadius: panelBaseRadius)
				imagePanel.eulerAngles.y = -degreesFromCenter * (.pi / 180.0)

				demoSceneView?.scene?.rootNode.addChildNode(imagePanel)
			}
		}

		func addClickRecognizer() {
			LogFunc()

			// ensure the click gesture recognizer is only added once
			guard clickGesture == nil, let sceneView = demoSceneView else {
				return
			}

			clickGesture = NSClickGestureRecognizer(target: sceneView, action: #selector(sceneView.handleClick(gesture:)))
			sceneView.addGestureRecognizer(clickGesture ?? NSClickGestureRecognizer() )

			sceneView.clickAction = { (results) in
				self.processHitTestResults(results)
			}
		}

		func addTextNodes() {
			LogFunc()
			let largeFontSize: CGFloat = 24
			let smallFontSize: CGFloat = 14

			let nameText = SCNText(string: "AltConf 2018", extrusionDepth: 2)
			nameText.font = .systemFont(ofSize: largeFontSize)
			nameText.materials = [SCNMaterial.white, SCNMaterial.white, SCNMaterial.black]	// front, back, extruded

			let nameTextNode = SCNNode()
			nameTextNode.geometry = nameText
			nameTextNode.pivotAtCorner(.allCorners)
			nameTextNode.position = positionForDegreesFromCenter(0, atRadius: 3, yOffset: -2)
			nameTextNode.scale = SCNVector3(baseNodeScale, baseNodeScale, baseNodeScale)
			nameTextNode.eulerAngles.x = -45 * (.pi / 180)

			demoSceneView?.scene?.rootNode.addChildNode(nameTextNode)

			let descriptionText = SCNText(string: "AR + SceneKit Tips and Tricks", extrusionDepth: 2)
			descriptionText.font = .systemFont(ofSize: smallFontSize)
			descriptionText.materials = [SCNMaterial.white, SCNMaterial.white, SCNMaterial.black]	// front, back, extruded

			let descriptionTextNode = SCNNode()
			descriptionTextNode.geometry = descriptionText
			descriptionTextNode.pivotAtCorner(.allCorners)
			descriptionTextNode.position = positionForDegreesFromCenter(0, atRadius: 2.8, yOffset: -2.5)
			descriptionTextNode.scale = SCNVector3(baseNodeScale, baseNodeScale, baseNodeScale)
			descriptionTextNode.eulerAngles.x = -45 * (.pi / 180)

			demoSceneView?.scene?.rootNode.addChildNode(descriptionTextNode)
		}

		public func processHitTestResults(_ results: [SCNHitTestResult]) {
			LogFunc()

			var tappedPanel: ImagePanel?

			results.forEach({ hitResult in

				if hitTestNaive {
					// see if we clicked an imageNode or one of its children
					// the problem with this approach is the image node includes things like lights
					// which are invisible and far from teh visible nodes.
					if let panel = hitResult.node as? ImagePanel {
						tappedPanel = panel
					} else if let panel = hitResult.node.parent as? ImagePanel {
						tappedPanel = panel
					}
				} else {
					// see if we clicked a panel node, header node, or content plane
						if let geometry = hitResult.node.geometry,
							let parent = hitResult.node.parent as? ImagePanel {
							if let _ = geometry as? SCNBox {
								tappedPanel = parent
							} else if let _ = geometry as? SCNPlane {
								tappedPanel = parent
							}
						}
				}
			})

			if let panel = tappedPanel {
				clickPanel(panel)
			}
		}

		func clickPanel(_ panel: ImagePanel) {
			LogFunc()

			moveCurrentPanelBack()

			if panel == currentPanel {
				currentPanel = nil
				return
			}

			currentPanel = panel

			if let image = panel.contentImage, let sceneView = demoSceneView {

				// Create an image for the inner surface of a cylinder
				// Since we want the image to only render on half of the inner circumference,
				// we need to make a new image that is double the original width,
				// with the image contents in the center, and no content on the outer 1/4's of the width
				let image2 = image.doubleWidth()

				let imageMaterial = SCNMaterial()
				imageMaterial.diffuse.contents = image2
				imageMaterial.lightingModel = .constant	// so we don't have to point a light at it to see it
				imageMaterial.isDoubleSided = true

				let cylinderRadius: CGFloat = image.size.width * baseNodeScale / 3
				let cylinder = SCNCylinder(radius: cylinderRadius, height: image.size.height * baseNodeScale)
				cylinder.materials = [imageMaterial, SCNMaterial.clear, SCNMaterial.clear]

				panel.animateToOpacity(0, withDuration: panelAnimationDuration)

				panel.animateToRotationRadians(panel.eulerAngles.y + .pi / 2, withDuration: panelAnimationDuration / 2, completion: {

					sceneView.scene?.rootNode.addChildNode(panel.imageNode)

					let initialScale = (panel.originalPanelGeometry.height / cylinder.height) * self.baseNodeScale * panel.scale.x
					panel.imageNode.scale = SCNVector3(initialScale, initialScale, initialScale)
					panel.imageNode.geometry = cylinder

					panel.imageNode.animateRotationByRadians((90 + 180) * .pi / 180, withDuration: self.panelAnimationDuration)
					panel.imageNode.animateToScale(SCNVector3Make(1, 1, 1), withDuration: self.panelAnimationDuration * 2)
				})
			}
		}

		func moveCurrentPanelBack() {
			LogFunc()

			guard let panel = currentPanel else {
				LogFunc("no current panel")
				return
			}

			panel.imageNode.animateRotationByRadians(.pi / 4, withDuration: panelAnimationDuration)
			panel.imageNode.animateToPosition(panel.originalImageNodePosition, withDuration: panelAnimationDuration)
			// scale along z faster to keep cylinder close to panel node
			panel.imageNode.animateToScale(SCNVector3(0.2, 0.2, 0.05), withDuration: panelAnimationDuration, completion: {
				panel.animateToOpacity(1, withDuration: self.panelAnimationDuration)
				panel.imageNode.animateToScale(SCNVector3(0.05, 0.05, 0.01), withDuration: self.panelAnimationDuration)
				panel.addChildNode(panel.imageNode)
				panel.animateRotationByRadians(.pi / 2, withDuration: self.panelAnimationDuration / 2, completion: {
					panel.reset()
					panel.animateRotationByRadians(.pi, withDuration: self.panelAnimationDuration)
				})
			})

		}

		func positionForDegreesFromCenter(_ degrees: CGFloat, atRadius radius: CGFloat, xOffset: CGFloat = 0, yOffset: CGFloat = 0) -> SCNVector3 {
			let radiansFromCenter = degrees * (.pi / 180.0)
			let x: CGFloat = sin(radiansFromCenter) * radius
			let z: CGFloat = cos(radiansFromCenter) * radius
			return SCNVector3(x + xOffset, yOffset, -z)
		}

		func positionForRadiansFromCenter(_ radians: Float, atRadius radius: CGFloat, yOffset: Float = 0) -> SCNVector3 {
			let degrees = CGFloat(-radians * 180 / .pi)
			return positionForDegreesFromCenter(degrees, atRadius: radius, yOffset:CGFloat(yOffset))
		}

		func degreesFromCenterForPanelIndex(_ index: Int) -> CGFloat {
			return ((CGFloat(index) - panelMidPoint) * panelSpacingDegrees)
		}

		func addMob() {
			LogFunc()

			guard let view = demoSceneView else {
				return
			}

			
			let scale: CGFloat = 0.01
			let nodeScale = SCNVector3(scale, scale, scale)
			let mobZLimit = panelBaseRadius
			let mobZBaseRadius = panelBaseRadius * 4

			let lowerRange = 15
			let upperRange = 50
			let randomMobCount = lowerRange + Int(arc4random_uniform(UInt32(upperRange - lowerRange)))

			let angleLimit = 45
			let positionXLimit = view.frame.size.width / 2
			let positionYBase = -view.frame.size.height * 0.25
			let positionYLimit = view.frame.size.height * 0.25

			let personMaterial = SCNMaterial()
			personMaterial.diffuse.contents = SKTexture(imageNamed: "user-blue")
			personMaterial.transparent.contents = SKTexture(imageNamed: "user-blue")

			(0..<randomMobCount).forEach({ index in

				let randomX = (CGFloat(-positionXLimit / 2) + CGFloat(arc4random_uniform(UInt32(positionXLimit)))) * scale
				let randomY = (CGFloat(-positionYLimit / 2) + CGFloat(arc4random_uniform(UInt32(positionYLimit))) + positionYBase) * scale
				let randomZ = -(mobZBaseRadius - mobZLimit + CGFloat(arc4random_uniform(UInt32(mobZLimit * 2))))
				let randomAngle = CGFloat(-angleLimit) + CGFloat(arc4random_uniform(UInt32(angleLimit * 2)))

				let randomMaterial = SCNMaterial()
				randomMaterial.diffuse.contents = personMaterial.diffuse.contents
				randomMaterial.transparent.contents = personMaterial.transparent.contents
				randomMaterial.transparency = alphaForZ(randomZ, baseRadius: mobZBaseRadius, zLimit: mobZLimit)

				let personObject = SCNBox(width: 200, height: 200, length: 0, chamferRadius: 0)
				personObject.materials = [personMaterial]
				let personNode = SCNNode(geometry: personObject)
				personNode.position = SCNVector3(randomX, randomY, randomZ)
				personNode.eulerAngles.y = randomAngle * (.pi / 180.0)
				personNode.scale = nodeScale
				view.scene?.rootNode.addChildNode(personNode)

				let randomZRange = CGFloat(arc4random_uniform(UInt32(mobZLimit)))
				let randomZDirection = CGFloat(Bool.randomSign())
				let randomZDuration = 5 + Double(arc4random_uniform(UInt32(15)))
				var zFrom = -mobZBaseRadius - randomZRange * randomZDirection
				var zTo = -mobZBaseRadius + randomZRange * randomZDirection

				if Bool.random() {
					let temp = zFrom
					zFrom = zTo
					zTo = temp
				}

				let animationZ = CABasicAnimation(keyPath: "position.z")
				animationZ.fromValue = zFrom
				animationZ.toValue = zTo
				animationZ.duration = randomZDuration
				animationZ.repeatCount = HUGE
				animationZ.autoreverses = true
				personNode.addAnimation(animationZ, forKey: "person move Z")

				let animationAlpha = CABasicAnimation(keyPath: "geometry.firstMaterial.transparency")
				animationAlpha.fromValue = alphaForZ(zFrom, baseRadius: mobZBaseRadius, zLimit: mobZLimit)
				animationAlpha.toValue = alphaForZ(zTo, baseRadius: mobZBaseRadius, zLimit: mobZLimit)
				animationAlpha.duration = randomZDuration
				animationAlpha.repeatCount = HUGE
				animationAlpha.autoreverses = true
				personNode.addAnimation(animationAlpha, forKey: "person alpha")

				let randomXRange = CGFloat(arc4random_uniform(UInt32(positionXLimit / 10)))
				let randomXDirection = CGFloat(Bool.randomSign())
				let randomXDuration = 7 + Double(arc4random_uniform(UInt32(20)))

				let animationX = CABasicAnimation(keyPath: "position.x")
				animationX.valueFunction = CAValueFunction(name: CAValueFunctionName.translateX)
				animationX.fromValue = -randomXRange * randomXDirection
				animationX.toValue = randomXRange * randomXDirection
				animationX.duration = randomXDuration
				animationX.repeatCount = HUGE
				animationX.autoreverses = true
				personNode.addAnimation(animationX, forKey: "person move X")
			})
		}

		func alphaForZ(_ z: CGFloat, baseRadius: CGFloat, zLimit: CGFloat) -> CGFloat {
			return 1.0 - abs(-z - baseRadius - zLimit) / (zLimit * 2)
		}


	}

}

