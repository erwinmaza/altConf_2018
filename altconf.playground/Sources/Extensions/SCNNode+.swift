// Erwin Mazariegos
// Altconf 2018: AR+SceneKit Tips & Tricks

import Foundation
import SceneKit

#if os(OSX)
	// case "other" is to silence warning about an unreachable default: case in switch statement
	// default: case is required because UIRectCorner is not actually an enum (it's an OptionSet)
	public enum NSRectCorner { case allCorners, topLeft, topRight, bottomLeft, bottomRight, other }
	public typealias RectCorner = NSRectCorner
	public typealias Color = NSColor
#else
	public typealias RectCorner = UIRectCorner
	public typealias Color = UIColor
#endif

extension SCNNode {

	convenience init(geometry: SCNGeometry, color: Color) {
		geometry.materials = [SCNMaterial.materialWithColor(color)]
		self.init(geometry: geometry)
	}

	public func animateToPosition(_ position: SCNVector3, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
		let animation = CABasicAnimation(keyPath: "position")
		animation.fromValue = self.position
		animation.toValue = position
		animation.duration = duration
		self.addAnimation(animation, forKey: "node move")
		self.position = position

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
			completion?()
		}
	}

	public func animatePositionBy(_ distance: CGFloat, alongAxis axis: SCNVector3, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {

		guard axis.x + axis.y + axis.z == 1, axis.x == 1 || axis.y == 1 || axis.z == 1 else {
			fatalError("'alongAxis' must be a unit vector along one of the primary axes")
		}

		let newPosition = SCNVector3(
			self.position.x + axis.x * distance,
			self.position.y + axis.y * distance,
			self.position.z + axis.z * distance)

		animateToPosition(newPosition, withDuration: duration, completion: completion)
	}

	public func animateToOpacity(_ opacity: CGFloat, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.fromValue = self.opacity
		animation.toValue = opacity
		animation.duration = duration
		self.addAnimation(animation, forKey: "node fade")
		self.opacity = opacity

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
			completion?()
		}
	}

	/// animates to a rotation angle around the Y axis
	public func animateToRotationRadians(_ angle: CGFloat, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
		let animation = CABasicAnimation(keyPath: "eulerAngles.y")
		animation.fromValue = self.eulerAngles.y
		animation.toValue = angle
		animation.duration = duration
		self.addAnimation(animation, forKey: "node rotate")
		self.eulerAngles.y = angle

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
			completion?()
		}
	}

	/// animates rotation around Y axis by specified radians
	public func animateRotationByRadians(_ angle: CGFloat, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
		let animation = CABasicAnimation(keyPath: "eulerAngles.y")
		animation.fromValue = self.eulerAngles.y
		animation.byValue = angle
		animation.duration = duration
		self.addAnimation(animation, forKey: "node rotate")
		self.eulerAngles.y += angle

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
			completion?()
		}
	}

	public func animateToScale(_ scale: SCNVector3, withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
		let animation = CABasicAnimation(keyPath: "scale")
		animation.fromValue = self.scale
		animation.toValue = scale
		animation.duration = duration
		self.addAnimation(animation, forKey: "node scale")
		self.scale = scale

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
			completion?()
		}
	}

	public func hasChildNode(_ node: SCNNode) -> Bool {
		var isChild = false
		self.enumerateChildNodes({ (child, stop) in
			if child == node {
				isChild = true
				stop.pointee = true
			}
		})
		return isChild
	}

	public func ancestorOfClass<T: SCNNode>(_ nodeClass: T.Type) -> T? {
		if let parentNode = parent {
			if type(of: parentNode) == nodeClass {
				return parentNode as? T
			} else {
				return parentNode.ancestorOfClass(nodeClass)
			}
		}
		return nil
	}

	public func showPivot(_ color: NSColor = .red) {
		// attempt to find a reasonable size for the pivot node based on the size and scale of this node
		let primarySize = max(0.1, ((boundingBox.max.x - boundingBox.min.x) + (boundingBox.max.y - boundingBox.min.y)) / 2)
		// arbritrarily divide by a factor to get a reasonable size. A node of radically differnt size or scale
		// might require a different adjustment
		let dotSize = CGFloat(primarySize / 30)
		let materialColor = SCNMaterial()
		materialColor.diffuse.contents = color
		let dot = SCNSphere(radius: dotSize)
		dot.materials = [materialColor]
		let dotNode = SCNNode(geometry: dot)
		dotNode.position.x = self.pivot.m41
		dotNode.position.y = self.pivot.m42
		dotNode.position.z = 0
		addChildNode(dotNode)
	}

	/// change pivot point of a node to a more useful corner. Supports nodes with SCNText, SCNBox, or SCNPlane geometries
	public func pivotAtCorner(_ corner: RectCorner, showPivotWithColor pivotColor: NSColor? = nil) {

		if let geometry = self.geometry as? SCNText, let text = geometry.string as? String {

			let textString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: geometry.font])
			var containerSize = geometry.containerFrame.size

			if containerSize == .zero {
				let textString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: geometry.font])
				containerSize = textString.boundingRect(with: geometry.containerFrame.size, options: .usesLineFragmentOrigin, context: nil).size

			}

			let container = NSTextContainer(size: containerSize)
			container.lineFragmentPadding = 0.0

			let layoutManager = NSLayoutManager()
			layoutManager.addTextContainer(container)

			let storage = NSTextStorage(attributedString: textString)
			storage.addLayoutManager(layoutManager)

			layoutManager.glyphRange(forBoundingRect: CGRect(origin: .zero, size: containerSize), in: container)

			var textSize = layoutManager.usedRect(for: container).size
			textSize.height = max(textSize.height, geometry.font.pointSize - geometry.font.descender)	// adjustment for single-line text

			geometry.containerFrame.size = textSize

			switch corner {
			case .allCorners:
				pivot = SCNMatrix4MakeTranslation(textSize.width / 2, textSize.height / 2, 0)
			case .topLeft:
				pivot = SCNMatrix4MakeTranslation(0, textSize.height, 0)
			case .topRight:
				pivot = SCNMatrix4MakeTranslation(textSize.width, textSize.height, 0)
			case .bottomLeft:
				pivot = SCNMatrix4Identity
			case .bottomRight:
				pivot = SCNMatrix4MakeTranslation(textSize.width, 0, 0)
			default:
				pivot = SCNMatrix4Identity
			}
		}

		if let size = sizeOfBoxOrPlane(self.geometry) {

			switch corner {
			case .allCorners:
				pivot = SCNMatrix4Identity
			case .topLeft:
				pivot = SCNMatrix4MakeTranslation(-size.width / 2, size.height / 2, 0)
			case .topRight:
				pivot = SCNMatrix4MakeTranslation(size.width / 2, size.height / 2, 0)
			case .bottomLeft:
				pivot = SCNMatrix4MakeTranslation(-size.width / 2, -size.height / 2, 0)
			case .bottomRight:
				pivot = SCNMatrix4MakeTranslation(size.width / 2, -size.height / 2, 0)
			default:
				pivot = SCNMatrix4Identity
			}
		}

		if let color = pivotColor {
			showPivot(color)
		}

	}

	/// only supports aligning to placeholder nodes with SCNBox or SCNPlane geometries
	public func alignToPlaceholder(_ placeholderNode: SCNNode, atCorner corner: RectCorner, hoverDistance: CGFloat = 0, showPivotWithColor pivotColor: NSColor? = nil) {

		guard parent == placeholderNode.parent else {
			fatalError("alignToPlaceholder: node and placeholder nodes are not siblings")
		}

		guard let size = sizeOfBoxOrPlane(placeholderNode.geometry) else {
			fatalError("alignToPlaceholder: placeholder geometry is not an SCNBox or SCNPlane")
		}

		self.pivotAtCorner(corner, showPivotWithColor: pivotColor)
		self.position = placeholderNode.position

		switch corner {
		case .topLeft:
			self.position.x -= CGFloat(size.width / 2)
			self.position.y += CGFloat(size.height / 2)
		case .topRight:
			self.position.x += CGFloat(size.width / 2)
			self.position.y += CGFloat(size.height / 2)
		case .bottomLeft:
			self.position.x -= CGFloat(size.width / 2)
			self.position.y -= CGFloat(size.height / 2)
		case .bottomRight:
			self.position.x += CGFloat(size.width / 2)
			self.position.y -= CGFloat(size.height / 2)
		default:
			break
		}

		self.position.z += size.depth + hoverDistance
	}

	public func showAxes() {
		addLetter("o", to: self, at: SCNVector3(0, 0, 0))
		addLetter("X", to: self, at: SCNVector3(1, 0, 0))
		addLetter("Y", to: self, at: SCNVector3(0, 1, 0))
		addLetter("Z", to: self, at: SCNVector3(0, 0, 1))
	}

	func addLetter(_ letter: String, to: SCNNode, at: SCNVector3) {
		let character = SCNText(string: letter, extrusionDepth: 1)
		character.materials = [SCNMaterial.black]
		let letterNode = SCNNode(geometry: character)
		letterNode.scale = SCNVector3(0.01, 0.01, 0.01)
		letterNode.position = at
		to.addChildNode(letterNode)
	}

	private func sizeOfBoxOrPlane(_ geometry: SCNGeometry?) -> (width: CGFloat, height: CGFloat, depth: CGFloat)? {
		if let box = geometry as? SCNBox {
			return (box.width, box.height, box.length)
		} else if let plane = geometry as? SCNPlane {
			return (plane.width, plane.height, 0)
		} else {
			return nil
		}
	}


}

